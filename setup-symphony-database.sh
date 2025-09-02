#!/bin/bash

# Symphony Database Setup Script
# This script populates a PostGIS database with Symphony test data for development

set -e  # Exit on any error

# Configuration
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-symphony}"
DB_USER="${DB_USER:-symphony}"
DB_PASSWORD="${DB_PASSWORD:-symphony}"
PGPASSWORD="$DB_PASSWORD"
export PGPASSWORD

# Test data paths
TEST_DATA_DIR="symphony-ws/src/test/resources"
TEMP_DIR="/tmp/symphony-import"
DATA_DIR="/workspace/test-data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to execute SQL with error checking
execute_sql() {
    local sql="$1"
    local description="$2"
    
    log_info "Executing: $description"
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" > /dev/null; then
        log_success "$description completed"
    else
        log_error "$description failed"
        return 1
    fi
}

# Function to execute SQL file
execute_sql_file() {
    local file="$1"
    local description="$2"
    
    log_info "Executing SQL file: $file - $description"
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file"; then
        log_success "$description completed"
    else
        log_error "$description failed"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if psql is available
    if ! command -v psql &> /dev/null; then
        log_error "psql command not found. Please install PostgreSQL client."
        exit 1
    fi
    
    # Check if test data exists
    if [ ! -d "$TEST_DATA_DIR" ]; then
        log_error "Test data directory not found: $TEST_DATA_DIR"
        exit 1
    fi
    
    # Test database connection
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_error "Cannot connect to database at $DB_HOST:$DB_PORT"
        log_error "Please check that the database is running and credentials are correct"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create temporary directories
setup_temp_directories() {
    log_info "Setting up temporary directories..."
    mkdir -p "$TEMP_DIR"
    mkdir -p "$DATA_DIR"
    log_success "Temporary directories created"
}

# Copy raster files to accessible location
copy_raster_files() {
    log_info "Copying test raster files to accessible location..."
    
    # Copy test raster files to workspace
    cp "$TEST_DATA_DIR/SGU-2019-multiband/ecocomponents-tiled-packbits.tif" "$DATA_DIR/ecocomponents-test.tif"
    cp "$TEST_DATA_DIR/SGU-2019-multiband/pressures-tiled-packbits.tif" "$DATA_DIR/pressures-test.tif"
    
    log_success "Raster files copied to $DATA_DIR"
}

# Create Symphony schema and import tables
create_schema_and_tables() {
    log_info "Creating Symphony schema and import tables..."
    
    # Create Symphony schema
    execute_sql "CREATE SCHEMA IF NOT EXISTS symphony AUTHORIZATION $DB_USER;" "Create Symphony schema"
    
    # Create essential tables based on the entity classes
    cat > "$TEMP_DIR/create_tables.sql" << 'EOF'
-- Create sequences
CREATE SEQUENCE IF NOT EXISTS symphony.bver_seq;
CREATE SEQUENCE IF NOT EXISTS symphony.carea_seq; 
CREATE SEQUENCE IF NOT EXISTS symphony.cap_seq;
CREATE SEQUENCE IF NOT EXISTS symphony.narea_seq;

-- Create baseline version table
CREATE TABLE IF NOT EXISTS symphony.baselineversion (
    bver_id integer PRIMARY KEY DEFAULT nextval('symphony.bver_seq'),
    bver_name text NOT NULL,
    bver_desc text,
    bver_locale varchar(10) NOT NULL DEFAULT 'en',
    bver_validfrom date NOT NULL,
    bver_ecofilepath text NOT NULL,
    bver_presfilepath text NOT NULL
);

-- Create meta bands table
CREATE TABLE IF NOT EXISTS symphony.meta_bands (
    metaband_id serial PRIMARY KEY,
    metaband_bver_id integer NOT NULL REFERENCES symphony.baselineversion(bver_id) ON DELETE CASCADE,
    metaband_category varchar(64) NOT NULL,
    metaband_number integer NOT NULL,
    metaband_default_selected boolean NOT NULL DEFAULT false,
    UNIQUE(metaband_bver_id, metaband_category, metaband_number)
);

-- Create meta values table
CREATE TABLE IF NOT EXISTS symphony.meta_values (
    metaval_id serial PRIMARY KEY,
    metaval_band_id integer NOT NULL REFERENCES symphony.meta_bands(metaband_id) ON DELETE CASCADE,
    metaval_language char(2) NOT NULL DEFAULT 'en',
    metaval_field text NOT NULL,
    metaval_value text NOT NULL,
    UNIQUE(metaval_band_id, metaval_language, metaval_field)
);

-- Create sensitivity matrix table
CREATE TABLE IF NOT EXISTS symphony.sensitivitymatrix (
    sensm_id serial PRIMARY KEY,
    sensm_name text NOT NULL,
    sensm_bver_id integer NOT NULL REFERENCES symphony.baselineversion(bver_id) ON DELETE CASCADE
);

-- Create calculation area table
CREATE TABLE IF NOT EXISTS symphony.calculationarea (
    carea_id integer PRIMARY KEY,
    carea_name text NOT NULL,
    carea_default_sensm_id integer REFERENCES symphony.sensitivitymatrix(sensm_id)
);

-- Create calculation area sensitivity matrix link table
CREATE TABLE IF NOT EXISTS symphony.calcareasensmatrix (
    casen_id serial PRIMARY KEY,
    casen_carea_id integer NOT NULL REFERENCES symphony.calculationarea(carea_id) ON DELETE CASCADE,
    casen_sensm_id integer NOT NULL REFERENCES symphony.sensitivitymatrix(sensm_id) ON DELETE CASCADE,
    casen_comment text,
    UNIQUE(casen_carea_id, casen_sensm_id)
);

-- Create sensitivity table
CREATE TABLE IF NOT EXISTS symphony.sensitivity (
    sens_id serial PRIMARY KEY,
    sens_sensm_id integer NOT NULL REFERENCES symphony.sensitivitymatrix(sensm_id) ON DELETE CASCADE,
    sens_pres_band_id integer NOT NULL REFERENCES symphony.meta_bands(metaband_id) ON DELETE CASCADE,
    sens_eco_band_id integer NOT NULL REFERENCES symphony.meta_bands(metaband_id) ON DELETE CASCADE,
    sens_value numeric NOT NULL,
    UNIQUE(sens_sensm_id, sens_pres_band_id, sens_eco_band_id)
);

-- Create area types table
CREATE TABLE IF NOT EXISTS symphony.areatype (
    atype_id serial PRIMARY KEY,
    atype_name text NOT NULL UNIQUE
);

-- Create national areas table (production schema)
CREATE TABLE IF NOT EXISTS symphony.nationalarea (
    narea_id integer PRIMARY KEY DEFAULT nextval('symphony.narea_seq'),
    narea_countryiso3 text NOT NULL,
    narea_type text NOT NULL,
    narea_areas text NOT NULL,
    narea_types text
);

-- Create calculation area polygon table (production schema)
CREATE TABLE IF NOT EXISTS symphony.capolygon (
    cap_id integer PRIMARY KEY DEFAULT nextval('symphony.cap_seq'),
    cap_carea_id integer NOT NULL REFERENCES symphony.calculationarea(carea_id) ON DELETE CASCADE,
    cap_polygon jsonb NOT NULL,
    pg_polygon geometry(MultiPolygon,4326)
);

-- Create system properties table
CREATE TABLE IF NOT EXISTS symphony.sysprop (
    sysprop_name text PRIMARY KEY,
    sysprop_value text NOT NULL
);

-- Create scenario table (updated schema to match Java entity)
CREATE TABLE IF NOT EXISTS symphony.scenario (
    id serial PRIMARY KEY,
    name text NOT NULL,
    owner text NOT NULL,
    timestamp timestamp NOT NULL,
    changes jsonb,
    baselineid integer REFERENCES symphony.baselineversion(bver_id) ON DELETE CASCADE,
    ecosystems integer[] NOT NULL DEFAULT '{}',
    pressures integer[] NOT NULL DEFAULT '{}',
    normalization_type integer NOT NULL DEFAULT 0,
    normalization_userdefinedvalue double precision NOT NULL DEFAULT 0.0,
    normalization_stddevmultiplier double precision NOT NULL DEFAULT 1.0,
    operation integer NOT NULL DEFAULT 0,
    operation_options jsonb,
    latestcalculation_cares_id integer REFERENCES symphony.calculationresult(cares_id)
);

-- Create scenario area table (required for scenario relationships)
CREATE TABLE IF NOT EXISTS symphony.scenarioarea (
    id serial PRIMARY KEY,
    changes jsonb,
    feature jsonb NOT NULL,
    matrix jsonb,
    scenario integer NOT NULL REFERENCES symphony.scenario(id) ON DELETE CASCADE,
    excluded_coastal integer,
    custom_calcarea integer REFERENCES symphony.calculationarea(carea_id),
    polygon geometry(MultiPolygon, 4326)
);

-- Create scenario snapshot table (extended production schema)
CREATE TABLE IF NOT EXISTS symphony.scenariosnapshot (
    id serial PRIMARY KEY,
    scenario_id integer REFERENCES symphony.scenario(id) ON DELETE CASCADE,
    changes jsonb NOT NULL,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    area_matrix_map jsonb,
    areas jsonb,
    baselineid integer REFERENCES symphony.baselineversion(bver_id),
    ecosystems integer[],
    name text,
    normalization_stddevmultiplier double precision DEFAULT 1.0,
    normalization_type integer DEFAULT 0,
    normalization_userdefinedvalue double precision DEFAULT 0.0,
    normalization_value double precision,
    owner text,
    polygon geometry(MultiPolygon, 4326),
    pressures integer[],
    timestamp timestamp DEFAULT CURRENT_TIMESTAMP
);

-- Create calculation result table (extended production schema)
CREATE TABLE IF NOT EXISTS symphony.calculationresult (
    cares_id serial PRIMARY KEY,
    cares_bver_id integer NOT NULL REFERENCES symphony.baselineversion(bver_id) ON DELETE CASCADE,
    cares_calculationname text NOT NULL,
    cares_timestamp timestamp NOT NULL,
    cares_owner text NOT NULL,
    cares_geotiff bytea,
    scenariosnapshot_id integer REFERENCES symphony.scenariosnapshot(id) ON DELETE CASCADE,
    cares_baselinecalculation boolean DEFAULT false,
    cares_image text,
    cares_impactmatrix jsonb,
    cares_op integer,
    cares_op_options jsonb
);

-- Create user settings table
CREATE TABLE IF NOT EXISTS symphony.usersettings (
    id serial PRIMARY KEY,
    "user" text NOT NULL UNIQUE,
    settings jsonb
);

-- Create user defined area table (production schema)
CREATE TABLE IF NOT EXISTS symphony.userdefarea (
    uda_id serial PRIMARY KEY,
    uda_name text NOT NULL,
    uda_owner text NOT NULL,
    uda_description text,
    uda_polygon text -- GeoJSON or WKT string
);

-- Create reliability partition table (for metadata bands uncertainty data)
CREATE TABLE IF NOT EXISTS symphony.reliabilitypartition (
    rp_id serial PRIMARY KEY,
    rp_metaband_id integer NOT NULL REFERENCES symphony.meta_bands(metaband_id) ON DELETE CASCADE,
    rp_polygon geometry(MultiPolygon, 3035),
    rp_value numeric
);

-- Create batch calculation table
CREATE TABLE IF NOT EXISTS symphony.batch_calculation (
    id serial PRIMARY KEY,
    name text NOT NULL,
    owner text NOT NULL,
    status text NOT NULL DEFAULT 'PENDING',
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at timestamp,
    completed_at timestamp
);

-- Create compound comparison table (for multi-calculation comparisons)
CREATE TABLE IF NOT EXISTS symphony.compoundcomparison (
    id serial PRIMARY KEY,
    baseline_id integer REFERENCES symphony.baselineversion(bver_id) ON DELETE CASCADE,
    cmp_name text NOT NULL,
    cmp_calculations integer[] NOT NULL DEFAULT '{}',
    cmp_result jsonb NOT NULL,
    cmp_owner text NOT NULL,
    cmp_timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Enable PostGIS if not already enabled
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create compatibility function for application code that incorrectly uses json_each() with jsonb
-- The application should use jsonb_each() but this allows the existing code to work
CREATE OR REPLACE FUNCTION json_each(input_jsonb jsonb)
RETURNS TABLE(key text, value jsonb)
LANGUAGE sql IMMUTABLE AS
$$
    SELECT * FROM jsonb_each(input_jsonb);
$$;
EOF

    execute_sql_file "$TEMP_DIR/create_tables.sql" "Create Symphony tables"
    log_success "Schema and tables created"
}

# Create database views
create_views() {
    log_info "Creating database views..."
    
    cat > "$TEMP_DIR/create_views.sql" << 'EOF'
-- Create calculation result slice view
CREATE OR REPLACE VIEW symphony.calculationresultslice AS
SELECT cr.cares_id AS id,
   cr.cares_bver_id AS baselineversion_id,
   cr.cares_calculationname AS calculationname,
   cr.cares_timestamp AS "timestamp",
   cr.cares_owner AS owner,
   cr.cares_geotiff IS NULL AS ispurged,
   COALESCE(
       (((s.changes ->> 'baseChanges'::text)::json) ->> 'PRESSURE'::text) IS NOT NULL
             OR (((s.changes ->> 'baseChanges'::text)::json) ->> 'ECOSYSTEM'::text) IS NOT NULL
             OR (( SELECT count(ac.key) AS count
                FROM json_each((s.changes ->> 'areaChanges'::text)::json) ac(key, value)
                WHERE NOT ac.value::text = '{}'::text)) > 0,
       false
   ) AS haschanges
  FROM symphony.calculationresult cr
    LEFT JOIN symphony.scenariosnapshot s ON cr.scenariosnapshot_id = s.id;
EOF

    execute_sql_file "$TEMP_DIR/create_views.sql" "Create database views"
    log_success "Database views created"
}

# Create baseline version
create_baseline_version() {
    log_info "Creating baseline version..."
    
    cat > "$TEMP_DIR/create_baseline.sql" << EOF
DO \$\$
DECLARE
    baselineName text := 'TESTDATA2024';
    baselineDesc text := 'Test data for Symphony development';
    baselineLocale text := 'en';
    validFrom date := CURRENT_DATE;
    eco_file_path text := '$DATA_DIR/ecocomponents-test.tif';
    pres_file_path text := '$DATA_DIR/pressures-test.tif';
    baseline_id integer;
BEGIN
    INSERT INTO symphony.baselineversion (
        bver_name, bver_desc, bver_locale, bver_validfrom, 
        bver_ecofilepath, bver_presfilepath
    )
    VALUES (
        baselineName, baselineDesc, baselineLocale, validFrom, 
        eco_file_path, pres_file_path
    )
    RETURNING bver_id INTO baseline_id;
    
    RAISE NOTICE 'Created baseline version with ID: %', baseline_id;
END \$\$;
EOF
    
    execute_sql_file "$TEMP_DIR/create_baseline.sql" "Create baseline version"
    log_success "Baseline version created"
}

# Generate and import metadata
import_metadata() {
    log_info "Generating and importing metadata..."
    
    # Create metadata import script
    cat > "$TEMP_DIR/import_metadata.sql" << 'EOF'
-- Import ecosystem and pressure metadata
DO $$
DECLARE
    baselineId integer := (SELECT bver_id FROM symphony.baselineversion WHERE bver_name = 'TESTDATA2024');
    bandTbl_id integer;
BEGIN
    -- Import ecosystem components
    INSERT INTO symphony.meta_bands 
    (metaband_bver_id, metaband_category, metaband_number, metaband_default_selected)
    VALUES 
    (baselineId, 'Ecosystem', 0, true),
    (baselineId, 'Ecosystem', 1, true);
    
    -- Insert metadata values for ecosystem components
    INSERT INTO symphony.meta_values 
    (metaval_band_id, metaval_language, metaval_field, metaval_value)
    SELECT 
        mb.metaband_id, 
        'en', 
        'title', 
        CASE mb.metaband_number 
            WHEN 0 THEN 'Test Ecosystem Component 1'
            WHEN 1 THEN 'Test Ecosystem Component 2'
        END
    FROM symphony.meta_bands mb 
    WHERE mb.metaband_bver_id = baselineId AND mb.metaband_category = 'Ecosystem';
    
    -- Import pressure components  
    INSERT INTO symphony.meta_bands
    (metaband_bver_id, metaband_category, metaband_number, metaband_default_selected) 
    VALUES 
    (baselineId, 'Pressure', 0, true),
    (baselineId, 'Pressure', 1, true);
    
    -- Insert metadata values for pressure components
    INSERT INTO symphony.meta_values
    (metaval_band_id, metaval_language, metaval_field, metaval_value)
    SELECT 
        mb.metaband_id, 
        'en', 
        'title', 
        CASE mb.metaband_number 
            WHEN 0 THEN 'Test Pressure Component 1'
            WHEN 1 THEN 'Test Pressure Component 2'
        END
    FROM symphony.meta_bands mb 
    WHERE mb.metaband_bver_id = baselineId AND mb.metaband_category = 'Pressure';
    
    RAISE NOTICE 'Metadata import completed';
END $$;
EOF

    execute_sql_file "$TEMP_DIR/import_metadata.sql" "Import metadata"
    log_success "Metadata imported"
}

# Import sensitivity matrix
import_sensitivity_matrix() {
    log_info "Importing sensitivity matrix..."
    
    # Create matrix import script
    cat > "$TEMP_DIR/import_matrix.sql" << 'EOF'
DO $$
DECLARE
    baselineId integer := (SELECT bver_id FROM symphony.baselineversion WHERE bver_name = 'TESTDATA2024');
    calcAreaId integer := 1;
    matrixName text := 'TestMatrix2024';
    isDefault boolean := true;
    
    nsensmId integer;
    casenId integer;
    
    ecoMetaId1 integer;
    ecoMetaId2 integer;
    presMetaId1 integer;
    presMetaId2 integer;
BEGIN
    -- Create sensitivity matrix
    INSERT INTO symphony.sensitivitymatrix(sensm_name, sensm_bver_id) 
    VALUES (matrixName, baselineId) 
    RETURNING sensm_id INTO nsensmId;
    
    -- Create calculation area if not exists
    INSERT INTO symphony.calculationarea (carea_id, carea_name, carea_default_sensm_id)
    VALUES (1, 'Test Calculation Area', nsensmId)
    ON CONFLICT (carea_id) DO UPDATE SET carea_default_sensm_id = nsensmId;
    
    -- Link matrix to calculation area
    INSERT INTO symphony.calcareasensmatrix(casen_carea_id, casen_sensm_id, casen_comment)
    VALUES (1, nsensmId, 'Test matrix (default)')
    ON CONFLICT (casen_carea_id, casen_sensm_id) DO NOTHING;
    
    -- Get band IDs
    SELECT metaband_id FROM symphony.meta_bands mb 
    JOIN symphony.meta_values mv ON mv.metaval_band_id = mb.metaband_id
    WHERE mb.metaband_bver_id = baselineId 
    AND mb.metaband_category = 'Ecosystem' 
    AND mv.metaval_field = 'title' 
    AND mv.metaval_value = 'Test Ecosystem Component 1'
    INTO ecoMetaId1;
    
    SELECT metaband_id FROM symphony.meta_bands mb 
    JOIN symphony.meta_values mv ON mv.metaval_band_id = mb.metaband_id
    WHERE mb.metaband_bver_id = baselineId 
    AND mb.metaband_category = 'Ecosystem' 
    AND mv.metaval_field = 'title' 
    AND mv.metaval_value = 'Test Ecosystem Component 2'
    INTO ecoMetaId2;
    
    SELECT metaband_id FROM symphony.meta_bands mb
    JOIN symphony.meta_values mv ON mv.metaval_band_id = mb.metaband_id  
    WHERE mb.metaband_bver_id = baselineId
    AND mb.metaband_category = 'Pressure'
    AND mv.metaval_field = 'title'
    AND mv.metaval_value = 'Test Pressure Component 1'
    INTO presMetaId1;
    
    SELECT metaband_id FROM symphony.meta_bands mb
    JOIN symphony.meta_values mv ON mv.metaval_band_id = mb.metaband_id
    WHERE mb.metaband_bver_id = baselineId
    AND mb.metaband_category = 'Pressure'  
    AND mv.metaval_field = 'title'
    AND mv.metaval_value = 'Test Pressure Component 2'
    INTO presMetaId2;
    
    -- Insert sensitivity values (2x2 matrix)
    INSERT INTO symphony.sensitivity (sens_sensm_id, sens_pres_band_id, sens_eco_band_id, sens_value)
    VALUES 
    (nsensmId, presMetaId1, ecoMetaId1, 0.3),
    (nsensmId, presMetaId1, ecoMetaId2, 0.5),
    (nsensmId, presMetaId2, ecoMetaId1, 0.4),
    (nsensmId, presMetaId2, ecoMetaId2, 0.2);
    
    RAISE NOTICE 'Sensitivity matrix import completed';
END $$;
EOF

    execute_sql_file "$TEMP_DIR/import_matrix.sql" "Import sensitivity matrix"
    log_success "Sensitivity matrix imported"
}

# Import test areas
import_areas() {
    log_info "Importing test areas..."
    
    cat > "$TEMP_DIR/import_areas.sql" << 'EOF'
DO $$
DECLARE
    geom geometry;
    area_id integer;
BEGIN
    INSERT INTO symphony.areatype (atype_name) VALUES ('Test Areas') ON CONFLICT (atype_name) DO NOTHING;
    
    -- Import simplified Lysekil polygon (using a simple rectangle for testing)
    SELECT ST_Transform(
        ST_SetSRID(
            ST_MakePolygon(
                ST_MakeLine(ARRAY[
                    ST_MakePoint(11.4, 58.2),
                    ST_MakePoint(11.6, 58.2), 
                    ST_MakePoint(11.6, 58.5),
                    ST_MakePoint(11.4, 58.5),
                    ST_MakePoint(11.4, 58.2)
                ])
            ), 4326
        ), 3035
    ) INTO geom;
    
    INSERT INTO symphony.nationalarea (narea_countryiso3, narea_type, narea_areas)
    VALUES ('SWE', 'Test Areas', '{"areas":[{"name":"Lysekil Test Area","geometry":"POLYGON((11.4 58.2,11.6 58.2,11.6 58.5,11.4 58.5,11.4 58.2))"}]}')
    RETURNING narea_id INTO area_id;
    
    RAISE NOTICE 'Imported test area with ID: %', area_id;
END $$;
EOF

    execute_sql_file "$TEMP_DIR/import_areas.sql" "Import test areas"
    log_success "Test areas imported"
}

# Create system properties
create_system_properties() {
    log_info "Creating system properties..."
    
    cat > "$TEMP_DIR/system_properties.sql" << 'EOF'
DO $$
BEGIN
    -- Insert basic system properties
    INSERT INTO symphony.sysprop (sysprop_name, sysprop_value) VALUES
        ('areas.countrycode', 'SE'),
        ('calc.normalization.histogram.percentile', '95')
    ON CONFLICT (sysprop_name) DO UPDATE SET sysprop_value = EXCLUDED.sysprop_value;
    
    RAISE NOTICE 'System properties created';
END $$;
EOF

    execute_sql_file "$TEMP_DIR/system_properties.sql" "Create system properties" 
    log_success "System properties created"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local baseline_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM symphony.baselineversion;" | tr -d ' ')
    local band_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM symphony.meta_bands;" | tr -d ' ')
    local matrix_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM symphony.sensitivitymatrix;" | tr -d ' ')
    local areas_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM symphony.nationalarea;" | tr -d ' ')
    
    log_info "Installation verification:"
    log_info "  Baseline versions: $baseline_count"
    log_info "  Metadata bands: $band_count"
    log_info "  Sensitivity matrices: $matrix_count" 
    log_info "  Areas: $areas_count"
    
    if [ "$baseline_count" -gt 0 ] && [ "$band_count" -gt 0 ]; then
        log_success "Database setup completed successfully!"
        log_info "Your Symphony database is now populated with test data and ready for development."
        log_info "Raster files are located in: $DATA_DIR"
    else
        log_error "Database setup may have failed. Please check the logs above."
        exit 1
    fi
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    log_success "Cleanup completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "Symphony Database Setup Script"
    echo "=========================================="
    echo
    
    check_prerequisites
    setup_temp_directories
    copy_raster_files
    create_schema_and_tables
    create_views
    create_baseline_version
    import_metadata
    import_sensitivity_matrix
    import_areas
    create_system_properties
    verify_installation
    cleanup
    
    echo
    echo "=========================================="
    log_success "Symphony database setup complete!"
    echo "=========================================="
    echo
    log_info "Next steps:"
    log_info "1. Start your Symphony backend application"
    log_info "2. Access the Symphony frontend to verify functionality"
    log_info "3. Use the cleanup-symphony-database.sh script to reset if needed"
}

# Run main function
main "$@"