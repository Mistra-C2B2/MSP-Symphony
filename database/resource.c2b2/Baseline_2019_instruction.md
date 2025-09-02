# Baseline 2019 installation package for MSP-Symphony v1.23/1.24-SNAPSHOT
The following is a 'fast track' instruction specifically meant to facilitate setting up a specific instance of the tool MSP-Symphony, using the same (unfortunately, slightly outdated) raster data stack used by **the Swedish Agency for Marine and Water Management** (**SwAM**).  

Please note that the method described in this instruction and scripts enclosed in this directory makes no attempt at generality.  

## Get the rasters
The preprocessed multi-band GeoTIFF rasters is enclosed as an attachment to a report about the tool, originally published in 2018, at **SwAMs** web domain.  
They may be found [here](https://www.havochvatten.se/download/18.5d3a53bc19898be468f88d96/1755612309164/MSP-Symphony_sv_Baseline2019.zip).  

Place them on some suitable path on the same filesystem as the app server, readable by the application.

## Get the area polygons
A package with the relevant area polygons, tailored specifically for this procedure is available for download [here](https://www.havochvatten.se/download/18.7d4f2b16198cd6eed1b4ec71/1756215271664/Symphony_sv_Polygons.zip).

As you'll see, the files in that archive are intrinsic to the 'Install baseline' script. Please note that the files need to be accessible to the database engine agent when running it.

## Prepare the PostgreSQL database
- Remember that the database needs to have [the **PostGIS** extension](https://postgis.net/) installed.  
**PostGIS** installation is not included in the enclosed setup scripts, and is required to be done before executing them.  
Run: 
```pgsql
CREATE EXTENSION postgis;
```
- The provided scripts assumes there is an application agent user configured for the app. This should be the same identity that is configured in the credentials for the data source in the app server (probably WildFly).  
The scripts can easily be modified to apply the username you've configured (the `DECLARE` section) appropriately.  
By default the username is set to `symphony` in the scripts.

Two setup scripts are enclosed in the [sql](./sql) directory relative to this instruction. 

If Hibernate's *hbm2ddl.auto* feature is activated to instantiate the schema at startup, the database structure itself needs to be adjusted <u>after</u> being initialized, <u>before</u> the API sees any usage, to avoid runtime errors.  
Regrettably, this apparent deficiency is not as yet remedied in the software (although most of the discrepancies have been documented, however obliquely, in the *Database schema changes* section of the release notes).  
Because of this, instead of relying on the (in this case hardly applicable) Hibernate feature, a schema creation procedure is included in the sql directory.

> [!TIP]
> For someone working with local instances of WildFly and PostgreSQL, there is an option to continue using 'hbm2ddl.auto', if one supplements it 
> after the 'automatic' initialization with running the [alternative script](./sql/alt/ALT-1__Reconfigure_database.sql).

If you're looking to run a containerised setup, such as with Docker, it's likely that you'll want to automate the initialization step entirely in your dockerfile.  
A workable approach might be to utilize Docker's [pre-seeding](https://docs.docker.com/guides/pre-seeding/#pre-seed-the-database-by-bind-mounting-a-sql-script) feature by moving the scripts into `/docker-entrypoint-initdb.d/`.

Something like:


```dockerfile
... 
# Copy initialization scripts
COPY database/resource.c2b2/sql/1__Create_schema.sql /docker-entrypoint-initdb.d/1-ddl.sql
COPY database/resource.c2b2/sql/2__Install_baseline_2019.sql /docker-entrypoint-initdb.d//2-baseline.sql
...
```


## Details to note

- The instance used at **SwAM** includes additional meta data that is not provided here, although only a quite small subset is included in the user interface and it's strictly auxiliary.  
However, the same information is available for download in human-readable format (PDF), [here](https://www.havochvatten.se/download/18.67e0eb431695d86393371d86/1708680041655/bilaga-1-symphony-metadata.zip).
- For GUI-heavy use, notice the application setting `data.cache_dir`. When set to a path writable by the application agent, it allows MSP-Symphony to build a fallback cache containing bitmaps of the individual baseline rasters per band, once they have been calculated. In the GUI, these images are displayed when the user interacts to show a band in the map view. Allowing the cache mechanism to present these image files instead of triggering a calculation covering the entire spatial extent every time a "data layer" is toggled, makes noticeable difference for the ux.
