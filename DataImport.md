# Data Import Guide for Symphony Ecosystem Components and Pressures

## Overview

This document describes the database structure and metadata requirements for importing ecosystem components and pressure data into Symphony. The information is based on analysis of the Symphony application code and existing database schema.

## Database Schema

### Core Tables

#### 1. symphony.meta_bands
Main table storing ecosystem and pressure components:

| Column | Type | Description |
|--------|------|-------------|
| metaband_id | integer (PK) | Unique identifier |
| metaband_bver_id | integer (FK) | References baseline version |
| metaband_category | varchar | "Ecosystem" or "Pressure" |
| metaband_number | integer | Band number (corresponds to raster band) |
| metaband_default_selected | boolean | Whether selected by default |

#### 2. symphony.meta_values
Metadata attributes for each band:

| Column | Type | Description |
|--------|------|-------------|
| metaval_id | integer (PK) | Unique identifier |
| metaval_band_id | integer (FK) | References meta_bands.metaband_id |
| metaval_language | varchar | Language code (e.g., "en", "sv") |
| metaval_field | varchar | Metadata field type |
| metaval_value | text | The actual metadata value |

#### 3. symphony.baselineversion
Baseline data versions:

| Column | Type | Description |
|--------|------|-------------|
| bver_id | integer (PK) | Baseline version ID |
| bver_name | varchar | Baseline name (e.g., "TESTDATA2024") |
| bver_ecofilepath | varchar | Path to ecosystem raster file |
| bver_presfilepath | varchar | Path to pressure raster file |

## Metadata Fields

### Required Core Fields

**title**
- Display name of the component
- Example: "Seagrass beds", "Marine mammals", "Shipping intensity"
- Used in frontend UI components

**symphonytheme** 
- Thematic grouping for UI organization
- Examples: "Benthos", "Fish", "Mammals", "Physical disturbance"
- Used for grouping components in the interface

### Extended Metadata Fields

#### Basic Information
- `multifname` - Multiband .tif filename
- `metadatafilename` - Metadata filename  
- `rasterfilename` - Raster file name
- `symphonydatatype` - Symphony Data Type
- `marineplanearea` - Marine Plan Area

#### Content Description
- `datecreated` - Date Created
- `datepublished` - Date Published
- `resourcetype` - Resource Type
- `format` - Data format
- `summary` - Summary description
- `limitationsforsymphony` - Limitations for Symphony usage
- `recommendations` - Usage recommendations
- `lineage` - Data lineage/history
- `status` - Data status

#### Contact Information
- `authororganisation` - Author Organisation
- `authoremail` - Author Email
- `dataowner` - Data Owner
- `owneremail` - Owner Email

#### Classification
- `topiccategory` - Topic Category
- `descriptivekeywords` - Descriptive Keywords
- `theme` - Theme classification
- `temporalperiod` - Temporal Period

#### Legal/Access
- `uselimitations` - Use Limitations
- `accessuserestrictions` - Access/Use Restrictions
- `otherrestrictions` - Other Restrictions
- `mapacknowledgement` - Map Acknowledgement
- `securityclassification` - Security Classification

#### Technical
- `maintenanceinformation` - Maintenance Information
- `spatialrepresentation` - Spatial Representation
- `rasterspatialreferencesystem` - Spatial Reference System
- `methodsummary` - Method Summary
- `valuerange` - Value Range
- `dataprocessing` - Data Processing
- `datasources` - Data Sources

#### Metadata Administration
- `metadatadate` - Metadata date
- `metadataorganisation` - Metadata Organisation
- `metadataemail` - Metadata Email
- `language` - Metadata Language

## Data Import Process

### 1. Prepare Baseline Version
```sql
INSERT INTO symphony.baselineversion (bver_name, bver_ecofilepath, bver_presfilepath)
VALUES ('YOUR_BASELINE_2024', '/path/to/ecosystem.tif', '/path/to/pressure.tif');
```

### 2. Import Component Bands
For each ecosystem or pressure component:
```sql
INSERT INTO symphony.meta_bands (metaband_bver_id, metaband_category, metaband_number, metaband_default_selected)
VALUES (baseline_version_id, 'Ecosystem', band_number, true/false);
```

### 3. Add Metadata Values
For each metadata field:
```sql
INSERT INTO symphony.meta_values (metaval_band_id, metaval_language, metaval_field, metaval_value)
VALUES (band_id, 'en', 'title', 'Component Display Name');
```

## Example: Complete Ecosystem Component

### Database Records
```sql
-- Baseline version
INSERT INTO symphony.baselineversion (bver_id, bver_name, bver_ecofilepath)
VALUES (1, 'BASELINE2024', '/data/ecosystem_2024.tif');

-- Component band
INSERT INTO symphony.meta_bands (metaband_id, metaband_bver_id, metaband_category, metaband_number, metaband_default_selected)
VALUES (1, 1, 'Ecosystem', 0, true);

-- Core metadata
INSERT INTO symphony.meta_values (metaval_band_id, metaval_language, metaval_field, metaval_value) VALUES
(1, 'en', 'title', 'Seagrass beds'),
(1, 'en', 'symphonytheme', 'Benthos'),
(1, 'en', 'summary', 'Distribution of seagrass beds in coastal areas'),
(1, 'en', 'datasources', 'Marine habitat mapping survey 2023'),
(1, 'en', 'authororganisation', 'Marine Research Institute'),
(1, 'en', 'datecreated', '2023-08-15'),
(1, 'en', 'valuerange', '0-100 (percentage coverage)'),
(1, 'en', 'spatialrepresentation', 'Raster 100m resolution');
```

## Frontend Integration

The metadata is consumed by the frontend through the `/metadata` REST endpoint and used in:

- **Component Selection**: Title and symphonytheme for grouping
- **Component Details**: All metadata fields available in `band.meta` object
- **User Interface**: Organized display of ecosystem/pressure components

## Key Considerations

1. **Raster Correspondence**: Band numbers must match actual raster band indices
2. **Multilingual Support**: Same metadata can be stored in multiple languages
3. **Thematic Organization**: symphonytheme field is critical for UI grouping
4. **Default Selection**: Controls which components are selected by default in scenarios
5. **Rich Metadata**: Extended fields provide comprehensive information for users

## Current Test Data Structure

The existing database contains minimal test data:
- 2 Ecosystem components (bands 0,1) 
- 2 Pressure components (bands 0,1)
- Only `title` metadata populated
- Missing `symphonytheme` and extended metadata

For production use, all relevant metadata fields should be populated to provide users with comprehensive information about each ecosystem component and pressure.