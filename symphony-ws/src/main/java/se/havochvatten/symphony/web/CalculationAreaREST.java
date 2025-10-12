package se.havochvatten.symphony.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import se.havochvatten.symphony.dto.AreaImportResponse;
import se.havochvatten.symphony.dto.CalculationAreaDto;
import se.havochvatten.symphony.entity.CalculationArea;
import se.havochvatten.symphony.exception.SymphonyModelErrorCode;
import se.havochvatten.symphony.exception.SymphonyStandardAppException;
import se.havochvatten.symphony.mapper.CalculationAreaMapper;
import se.havochvatten.symphony.service.CalculationAreaService;

import jakarta.annotation.security.RolesAllowed;
import jakarta.ejb.EJB;
import jakarta.ejb.Stateless;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.commons.io.IOUtils;
import org.geotools.geopkg.GeoPackage;
import org.jboss.resteasy.plugins.providers.multipart.InputPart;
import org.jboss.resteasy.plugins.providers.multipart.MultipartFormDataInput;

@Stateless
@Tag(name = "/calculationarea")
@Path("calculationarea")
@RolesAllowed("GRP_SYMPHONY")
public class CalculationAreaREST {
    private static final Logger LOG = Logger.getLogger(CalculationAreaREST.class.getName());
    private static final java.nio.file.Path TEMP_DIR = Paths.get(System.getProperty("java.io.tmpdir"));

    @EJB
    CalculationAreaService calculationAreaService;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Get all calculation areas for baselineName defined in the system")
    @Path("all/{baselineName}")
    public Response findCalculationAreas(@PathParam("baselineName") String baselineName) {
        List<CalculationArea> resp = calculationAreaService.findCalculationAreas(baselineName);
        if (resp != null) {
            return Response.ok(resp
                            .stream()
                            .map(CalculationAreaMapper::mapToDto)
                            .toList())
                    .build();
        } else
            return Response.noContent().build();
    }

    @GET
    @Path("{id}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Get calculation area on id")
    public Response get(@PathParam("id") Integer id) throws SymphonyStandardAppException {
        CalculationAreaDto calculationAreaDto = calculationAreaService.get(id);
        return Response.ok(calculationAreaDto).build();
    }

    @GET
    @Path("calibrated/{baselineName}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Get all calculation areas for baselineName defined in the system " +
                          "for which a max value has been set")
    public Response findCalibratedCalculationAreas(@PathParam("baselineName") String baselineName) {
        List<CalculationArea> resp = calculationAreaService.findCalibratedCalculationAreas(baselineName);

        if (resp != null) {
            return Response.ok(resp
                            .stream()
                            .map(CalculationAreaMapper::mapToSparseDto)
                            .toList())
                    .build();
        } else
            return Response.noContent().build();
    }

    @POST
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Create a CalculationArea")
    public Response create(@Context UriInfo uriInfo, CalculationAreaDto calculationAreaDto) throws SymphonyStandardAppException {
        calculationAreaDto = calculationAreaService.create(calculationAreaDto);
        URI uri = uriInfo.getAbsolutePathBuilder().path(String.valueOf(calculationAreaDto.getId())).build();
        return Response.created(uri).entity(calculationAreaDto).build();
    }

    @POST
    @Path("/import")
    @Operation(summary = "Submit a GeoPackage for inspection with intent to have it imported")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public Response uploadAndInspectCalculationArea(@Context HttpServletRequest req,
                                                    MultipartFormDataInput input)
        throws SymphonyStandardAppException, IOException {

        var map = input.getFormDataMap();
        if (!map.containsKey("package"))
            throw new BadRequestException();

        var parts = map.get("package");
        InputPart part = parts.get(0);
        LOG.info(() -> "Received file: "+getFilenameFromHeader(part.getHeaders()));
        // TODO: verify content-type?

        // Write received file to a tempfile since GeoPackage constructor can only take file objects
        java.nio.file.Path packagePath = null;
        File packageFile;
        try {
            InputStream inputStream = part.getBody(InputStream.class, null);
            byte[] bytes = IOUtils.toByteArray(inputStream);
            packagePath = Files.createTempFile(TEMP_DIR, null, null);
            packageFile = packagePath.toFile();
            WebUtil.writeFile(bytes, packageFile);
        } catch (IOException e) {
            if (packagePath != null)
                Files.deleteIfExists(packagePath);
            throw new SymphonyStandardAppException(SymphonyModelErrorCode.GEOPACKAGE_OPEN_ERROR);
        }

        try {
            var dto = calculationAreaService.inspectGeoPackage(packageFile);
            req.getSession().setAttribute(dto.key, packagePath.toFile());
            return Response.ok(dto).build();
        } catch (SymphonyStandardAppException|java.lang.reflect.UndeclaredThrowableException e) {
            Files.delete(packagePath);
            throw e;
        }
    }

    @PUT
    @Path("/import/{key}")
    @Operation(summary = "Confirm import of previously uploaded GeoPackage")
    @Produces(MediaType.APPLICATION_JSON)
    public Response actuallyImportCalculationArea(@Context HttpServletRequest req,
                                                  @Context UriInfo uriInfo,
                                                  @PathParam("key") String key)
        throws SymphonyStandardAppException {
        var pkgFile = (java.io.File) req.getSession(false).getAttribute(key);

        AreaImportResponse response;
        try (var pkg = new GeoPackage(pkgFile)) {
            LOG.log(Level.INFO,
                () -> String.format("Importing uploaded GeoPackage %s for user %s", pkgFile ,req.getUserPrincipal().getName()));
                
            response = calculationAreaService.importCalculationAreaFromPackage(req.getUserPrincipal(), pkg);
        } catch (IOException e) {
            throw new SymphonyStandardAppException(SymphonyModelErrorCode.GEOPACKAGE_READ_FEATURE_FAILURE);
        }

        req.getSession().removeAttribute(key);
//        Files.deleteIfExists(pkgPath); // fails since file is still used by other process?? how to close?
        return Response.status(201).entity(response).build();
    }

    /**
     * header sample
     * {
     * 	Content-Type=[image/png],
     * 	Content-Disposition=[form-data; name="file"; filename="filename.extension"]
     * }
     *
     * Copied from https://mkyong.com/webservices/jax-rs/file-upload-example-in-resteasy/
     **/
    private String getFilenameFromHeader(MultivaluedMap<String, String> header) {
        String[] contentDisposition = header.getFirst("Content-Disposition").split(";");
        for (String filename : contentDisposition) {
            if ((filename.trim().startsWith("filename"))) {
                String[] name = filename.split("=");
                return name[1].trim().replace("\"", "");
            }
        }
        return null;
    }

    @PUT
    @Path("{id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Update CalculationArea")
    public Response update(@PathParam("id") Integer id, CalculationAreaDto calculationAreaDto) throws SymphonyStandardAppException {
        calculationAreaDto.setId(id);
        calculationAreaDto = calculationAreaService.update(calculationAreaDto);
        return Response.ok(calculationAreaDto).build();
    }

    @DELETE
    @Path("{id}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Delete CalculationArea")
    public Response deleteCalcAreaSensMatrix(@PathParam("id") Integer id) throws SymphonyStandardAppException {
        calculationAreaService.delete(id);
        return Response.ok().build();
    }
}
