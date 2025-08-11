# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

Symphony is a marine spatial planning tool with a Jakarta EE backend and Angular 17 frontend. The system follows a 3-tier architecture:

- **Frontend**: Angular 17 SPA with TypeScript, NgRx for state management, Angular Material UI, and OpenLayers for mapping
- **Backend**: Jakarta EE 10 web services using JAX-RS, JPA/Hibernate, and PostgreSQL with PostGIS extensions  
- **Database**: PostgreSQL 14+ with PostGIS for spatial data and raster filesystem storage

Key architectural patterns:
- RESTful API design with JAX-RS endpoints in `symphony-ws/src/main/java/se/havochvatten/`
- NgRx store pattern for frontend state management in `frontend/src/app/data/`
- Modular Angular components organized by feature areas in `frontend/src/app/`
- Batch processing using Jakarta Batch API for long-running calculations

## Development Commands

### Backend (Maven)
```bash
cd symphony-ws
mvn package -DskipTests          # Build WAR file
mvn test                         # Run unit tests (excludes API tests)
mvn test -Ponly-apitests        # Run API tests only
mvn wildfly:deploy              # Deploy to local Wildfly
```

### Frontend (Angular CLI)
```bash
cd frontend
npm install                      # Install dependencies  
ng serve --ssl                   # Dev server with SSL (port 4200)
ng build                         # Development build
ng build --configuration production  # Production build
ng test                         # Run unit tests with Karma
ng test --watch=false --browsers=ChromeCI  # Headless test run
ng lint                         # ESLint checking
```

### Development Environment
The application runs in a devcontainer environment with services accessible at:
- Database: postgresql://db:5432/symphony (user: symphony, password: symphony)
- Backend: localhost:8080
- Frontend: localhost:4200

## Testing

### Backend Tests
- Unit tests: Default `mvn test` excludes API tests
- API tests: Use `-Ponly-apitests` profile, requires credentials in properties
- Test credentials set via properties: `symphony.username`, `symphony.password`, `symphony.adminusername`, `symphony.adminpassword`

### Frontend Tests  
- Unit tests with Karma: `ng test`
- Coverage reports generated automatically
- ESLint for code quality: `ng lint`

## Key Technologies & Dependencies

### Backend Stack
- Java 17, Jakarta EE 10
- Wildfly 36 (recommended app server)
- PostgreSQL 14+ with PostGIS extensions
- GeoTools 29.6 for spatial operations
- Hibernate 6.6 for ORM
- Jackson for JSON processing

### Frontend Stack
- Angular 17 with TypeScript 5.4
- NgRx 17 for state management
- Angular Material for UI components
- OpenLayers 9.2 for mapping functionality
- D3.js for data visualizations
- Turf.js for spatial calculations

## Project Structure

### Backend (`symphony-ws/src/main/java/se/havochvatten/`)
- Service layer: RESTful endpoints and business logic
- Entity layer: JPA entities for database mapping  
- Batch jobs: Long-running calculation processing

### Frontend (`frontend/src/app/`)
- `data/`: NgRx stores, effects, and services by feature
- `map-view/`: Main application interface and map components
- `shared/`: Reusable UI components and utilities
- `report/`: Calculation result visualization components

## Environment Configuration

### Backend Configuration
- Main config: `symphony-ws/src/main/resources/symphony.properties`
- Override config: `/app/config/symphony/symphony-global.properties`
- Requires SymphonyDS datasource and LDAPAuth security domain in Wildfly

### Frontend Configuration
- Environment files: `frontend/src/environments/`
- Proxy configuration: `frontend/proxy.conf.js`
- SSL certificates: `frontend/ssl/`

## Development Notes

- Backend requires minimum 2GB heap space (`-Xmx2G`)
- UTF-8 encoding required (`-Dfile.encoding=UTF-8` on Windows)
- Frontend uses strict TypeScript configuration
- Code formatting enforced via Prettier and lint-staged
- Git hooks run linting on pre-commit and pre-push