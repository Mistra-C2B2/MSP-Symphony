# Changelog

All notable changes to the Symphony frontend will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

#### Frontend Stability & Error Handling

- **Fixed NgRx selector crashes during app initialization**
  - Added null checks in `area.selectors.ts` for `boundaries.map()` operations
  - Added defensive programming for `nationalArea.groups` and `group.areas` access
  - Prevents `"can't access property 'map', boundaries is undefined"` errors
  - Prevents `"can't access property 'reduce', nationalArea.groups is undefined"` errors
  - Files: `frontend/src/app/data/area/area.selectors.ts`

- **Fixed area data processing failures in NgRx effects**
  - Added optional chaining (`?.`) in `flattenAreaGroups()` function for `nationalArea.groups`
  - Added optional chaining in `flattenAreas()` function for areas array processing
  - Added fallback empty objects/arrays to prevent reduce operations on undefined data
  - Files: `frontend/src/app/data/area/area.effects.ts`

- **Fixed map component race condition with area highlighting**
  - Added guard check in `highlightArea()` method to prevent access to uninitialized `areaHighlightLayer`
  - Prevents `"this.areaHighlightLayer is undefined"` errors during component initialization
  - Files: `frontend/src/app/map-view/map/map.component.ts`

- **Fixed DOM access timing issues in area layer**
  - Replaced dangerous non-null assertion (`!`) with proper null checking for `area-options-menu` element
  - Added early return when DOM elements are not yet available during Angular lifecycle
  - Prevents `"can't access property 'addEventListener', optionsMenuElement is null"` errors
  - Files: `frontend/src/app/map-view/map/layers/area-layer.ts`

#### Backend Data & API Issues

- **Fixed empty API responses due to browser caching**
  - Identified that AreasREST endpoints set 1-year cache headers (`Cache-Control: max-age=31536000`)
  - Empty responses from initial development were cached by browsers
  - Resolution: Hard refresh required after backend data population
  - Note: This is a backend caching configuration issue, not a frontend bug

- **Added minimal national area and boundary test data**
  - Populated `symphony.nationalarea` table with test data for MSP, COUNTY, PROTECTED, and BOUNDARY types
  - Prevents backend `NoResultException` when frontend requests area data
  - Enables area selection functionality in development environment

#### Database Schema Fixes

- **Updated database schema to match Java entity expectations**
  - Fixed table/column naming mismatches between database and JPA entities
  - Updated `setup-symphony-database.sh` to include production-ready schema
  - Added missing tables: `userdefarea`, `compoundcomparison`, `reliabilitypartition`
  - Fixed JSON compatibility function for PostgreSQL

### Technical Details

#### Root Causes Addressed

1. **Component Lifecycle Timing Issues**
   - Angular components accessing resources before full initialization
   - DOM elements being accessed before template rendering completes
   - NgRx selectors running before API data is available

2. **Defensive Programming Improvements**
   - Added null/undefined checks throughout the application
   - Implemented optional chaining for safe property access
   - Added fallback values for graceful degradation

3. **Backend Integration Issues**
   - Browser caching of empty responses during development
   - Missing database test data for development environment
   - Schema mismatches between database and application entities

#### Impact

- ✅ **Eliminated frontend crashes** during application startup
- ✅ **Improved user experience** with smooth area loading
- ✅ **Enhanced error resilience** for timing edge cases
- ✅ **Enabled area visualization** functionality in development environment
- ✅ **Resolved authentication and database integration** issues

#### Compatibility

- **Angular**: Compatible with existing Angular 17 architecture
- **OpenLayers**: No breaking changes to map functionality
- **NgRx**: Maintains existing state management patterns
- **Backend**: Requires backend database schema updates and test data

#### Migration Notes

- Frontend changes are backward compatible
- Hard browser refresh required after applying backend data fixes
- Development environments need database schema updates via `setup-symphony-database.sh`

---

## Previous Releases

_Previous changelog entries would be added here as the project evolves._