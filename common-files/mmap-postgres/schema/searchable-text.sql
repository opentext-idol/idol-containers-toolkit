DROP TABLE IF EXISTS searchableVideoEvent;

CREATE OR REPLACE VIEW searchableVideoEvent AS
SELECT
  videoevent.*,
  lower(CONCAT_WS(
    E'\x1f',
    face.name,
    face.database,
    logo.name,
    logo.database,
    ocr.text,
    sceneanalysis.category,
    CONCAT_WS(
      ' ',
      licenseplate.vehiclecolorname,
      licenseplate.vehiclemake
    ),
    array_to_string(
      array(SELECT licenseplateread.text FROM licenseplateread WHERE licenseplateread.licenseplate = videoevent.id LIMIT 10),
      ' '
    ),
    annotation.label
  )) AS searchabletext
FROM videoevent
  LEFT JOIN face ON videoevent.id = face.id
  LEFT JOIN logo ON videoevent.id = logo.id
  LEFT JOIN ocr  ON videoevent.id = ocr.id
  LEFT JOIN sceneanalysis ON videoevent.id = sceneanalysis.id
  LEFT JOIN licenseplate ON videoevent.id = licenseplate.id
  LEFT JOIN annotation ON videoevent.id = annotation.id;
