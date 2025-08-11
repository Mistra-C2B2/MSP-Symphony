#!/bin/bash

# Symphony Database Cleanup Script
# This script removes all Symphony data from the PostGIS database

set -e  # Exit on any error

# Configuration
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-symphony}"
DB_USER="${DB_USER:-symphony}"
DB_PASSWORD="${DB_PASSWORD:-symphony}"
PGPASSWORD="$DB_PASSWORD"
export PGPASSWORD

# Data directory 
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
        log_warning "$description failed or already clean"
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
    
    # Test database connection
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_error "Cannot connect to database at $DB_HOST:$DB_PORT"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Function to get user confirmation
confirm_cleanup() {
    echo "=========================================="
    log_warning "DATABASE CLEANUP WARNING"
    echo "=========================================="
    echo
    log_warning "This script will completely remove all Symphony data from your database:"
    echo "  • All baseline versions and associated data"
    echo "  • All metadata bands and values"
    echo "  • All sensitivity matrices"
    echo "  • All calculation areas and scenarios"  
    echo "  • All imported geographic areas"
    echo "  • All raster files from $DATA_DIR"
    echo "  • The entire Symphony schema"
    echo
    log_error "THIS OPERATION CANNOT BE UNDONE!"
    echo
    
    read -p "Are you sure you want to proceed? Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    echo
    log_warning "Starting cleanup in 3 seconds... Press Ctrl+C to cancel"
    sleep 3
}

# Create backup of current state (optional)
create_backup() {
    log_info "Creating backup of current database state..."
    
    local backup_file="/tmp/symphony_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" --schema=symphony > "$backup_file" 2>/dev/null; then
        log_success "Database backup created: $backup_file"
        log_info "You can restore this backup if needed using:"
        log_info "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < $backup_file"
    else
        log_warning "Backup creation failed or no Symphony schema exists"
    fi
}

# Remove raster files
remove_raster_files() {
    log_info "Removing raster files from workspace..."
    
    rm -f "$DATA_DIR/ecocomponents-test.tif" || true
    rm -f "$DATA_DIR/pressures-test.tif" || true
    rmdir "$DATA_DIR" 2>/dev/null || true
    
    log_success "Raster files removed"
}

# Drop Symphony data in dependency order
drop_symphony_data() {
    log_info "Dropping Symphony data tables in dependency order..."
    
    # Drop data tables in reverse dependency order
    execute_sql "DROP TABLE IF EXISTS symphony.sensitivity CASCADE;" "Drop sensitivity table"
    execute_sql "DROP TABLE IF EXISTS symphony.meta_values CASCADE;" "Drop metadata values table"
    execute_sql "DROP TABLE IF EXISTS symphony.reliabilitypartition CASCADE;" "Drop reliability partitions"
    execute_sql "DROP TABLE IF EXISTS symphony.meta_bands CASCADE;" "Drop metadata bands table"
    execute_sql "DROP TABLE IF EXISTS symphony.calcareasensmatrix CASCADE;" "Drop calculation area sensitivity matrix links"
    execute_sql "DROP TABLE IF EXISTS symphony.sensitivitymatrix CASCADE;" "Drop sensitivity matrices"
    execute_sql "DROP TABLE IF EXISTS symphony.calculationresult CASCADE;" "Drop calculation results"
    execute_sql "DROP TABLE IF EXISTS symphony.scenariosnapshot CASCADE;" "Drop scenario snapshots"
    execute_sql "DROP TABLE IF EXISTS symphony.scenarioarea CASCADE;" "Drop scenario areas"
    execute_sql "DROP TABLE IF EXISTS symphony.scenario CASCADE;" "Drop scenarios"
    execute_sql "DROP TABLE IF EXISTS symphony.capolygon CASCADE;" "Drop calculation area polygons"
    execute_sql "DROP TABLE IF EXISTS symphony.calculationarea CASCADE;" "Drop calculation areas"
    execute_sql "DROP TABLE IF EXISTS symphony.nationalarea CASCADE;" "Drop national areas"
    execute_sql "DROP TABLE IF EXISTS symphony.areatype CASCADE;" "Drop area types"
    execute_sql "DROP TABLE IF EXISTS symphony.baselineversion CASCADE;" "Drop baseline versions"
    execute_sql "DROP TABLE IF EXISTS symphony.sysprop CASCADE;" "Drop system properties"
    execute_sql "DROP TABLE IF EXISTS symphony.userdefarea CASCADE;" "Drop user defined areas"
    execute_sql "DROP TABLE IF EXISTS symphony.usersettings CASCADE;" "Drop user settings"
    execute_sql "DROP TABLE IF EXISTS symphony.batch_calculation CASCADE;" "Drop batch calculations"
    execute_sql "DROP TABLE IF EXISTS symphony.compoundcomparison CASCADE;" "Drop compound comparisons"
    
    log_success "Symphony data tables dropped"
}

# Drop import schema and tables
drop_import_schema() {
    log_info "Dropping import schema and tables..."
    
    execute_sql "DROP SCHEMA IF EXISTS import CASCADE;" "Drop import schema"
    
    log_success "Import schema dropped"
}

# Drop sequences
drop_sequences() {
    log_info "Dropping Symphony sequences..."
    
    execute_sql "DROP SEQUENCE IF EXISTS symphony.bver_seq CASCADE;" "Drop baseline version sequence"
    execute_sql "DROP SEQUENCE IF EXISTS symphony.carea_seq CASCADE;" "Drop calculation area sequence"
    execute_sql "DROP SEQUENCE IF EXISTS symphony.cap_seq CASCADE;" "Drop calculation area polygon sequence"
    execute_sql "DROP SEQUENCE IF EXISTS symphony.narea_seq CASCADE;" "Drop national area sequence"
    
    log_success "Sequences dropped"
}

# Drop Symphony schema completely
drop_symphony_schema() {
    log_info "Dropping Symphony schema..."
    
    execute_sql "DROP SCHEMA IF EXISTS symphony CASCADE;" "Drop Symphony schema"
    
    log_success "Symphony schema dropped"
}

# Verify cleanup completion
verify_cleanup() {
    log_info "Verifying cleanup completion..."
    
    local schema_exists=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'symphony');" 2>/dev/null || echo "f")
    local import_schema_exists=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'import');" 2>/dev/null || echo "f")
    
    schema_exists=$(echo "$schema_exists" | tr -d ' ' | tr -d '\n')
    import_schema_exists=$(echo "$import_schema_exists" | tr -d ' ' | tr -d '\n')
    
    log_info "Cleanup verification:"
    log_info "  Symphony schema exists: $schema_exists"
    log_info "  Import schema exists: $import_schema_exists"
    
    if [ "$schema_exists" = "f" ] && [ "$import_schema_exists" = "f" ]; then
        log_success "Database cleanup completed successfully!"
        log_info "All Symphony data has been removed from the database."
    else
        log_warning "Some data may still remain. You may need to run the cleanup again."
    fi
}

# Main cleanup function
perform_cleanup() {
    log_info "Starting Symphony database cleanup..."
    
    create_backup
    remove_raster_files
    drop_symphony_data
    drop_sequences
    drop_import_schema
    drop_symphony_schema
    verify_cleanup
    
    log_success "Cleanup process completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "Symphony Database Cleanup Script"
    echo "=========================================="
    echo
    
    check_prerequisites
    confirm_cleanup
    perform_cleanup
    
    echo
    echo "=========================================="
    log_success "Symphony database cleanup complete!"
    echo "=========================================="
    echo
    log_info "Your database has been reset to a clean state."
    log_info "To populate it again, run: ./setup-symphony-database.sh"
}

# Handle script interruption
trap 'echo -e "\n${RED}[ERROR]${NC} Cleanup interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"