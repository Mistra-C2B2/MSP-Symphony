package se.havochvatten.symphony.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import se.havochvatten.symphony.exception.SymphonyStandardAppException;
import se.havochvatten.symphony.service.UserService;

import jakarta.annotation.security.RolesAllowed;
import jakarta.ejb.EJB;
import jakarta.ejb.Stateless;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import java.util.Map;

import static se.havochvatten.symphony.web.WebUtil.noPrincipalStr;

@Stateless
@Tag(name = "/usersettings")
@Path("user")
public class UserREST {

    @EJB
    UserService userService;

    @PUT
    @Path("/settings")
    @Operation(summary = "Update user settings")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @RolesAllowed("GRP_SYMPHONY")
    public Response updateUserSettings(@Context HttpServletRequest req, Map<String, Object> settings) {
        if (req.getUserPrincipal() == null)
            throw new NotAuthorizedException(noPrincipalStr);

        try {
            userService.updateUserSettings(req.getUserPrincipal(), settings);
            return Response.ok().build();
        } catch (SymphonyStandardAppException e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(e).build();
        }
    }

}
