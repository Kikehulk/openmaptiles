-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE FUNCTION convert_poi_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_poi_polygon SET geometry=topoint(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
  ANALYZE osm_poi_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT convert_poi_point();

-- Handle updates

CREATE SCHEMA poi;

CREATE TABLE IF NOT EXISTS poi.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION poi.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO poi.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION poi.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh poi';
    SELECT convert_poi_point();
    DELETE FROM poi.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_poi_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE poi.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON poi.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE poi.refresh();
