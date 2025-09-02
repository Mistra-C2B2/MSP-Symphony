DO $$
DECLARE
    r RECORD;
    schema_name TEXT := 'symphony';
BEGIN
    -- Loop through all tables in the specified schema, truncate and reset identity sequence
    FOR r IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = schema_name
    LOOP
        EXECUTE format('TRUNCATE %I.%I RESTART IDENTITY CASCADE;', schema_name, r.tablename);
    END LOOP;
END $$;
