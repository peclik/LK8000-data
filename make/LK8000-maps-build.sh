#!/bin/bash -e
# ------------------------------------------------------------------------------
# Creates maps for LK8000 from OSM maps.
#
# MIT License
#
# Copyright (c) 2025 Aviax/.cz
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Description:
#  * This script creates an .lkm map package for use with LK8000.
#  * The topology.tpl file contains descriptions of topology layers.
#    **Notice:** The topology.tpl uses a legacy format, allowing zoom ranges
#            for each layer to be fine-tuned. As a result, user-defined range
#            settings in LK8000 are not functional.
#
# Usage:
#
# 1. Install the required dependencies:
#   * `QGIS` application  (for qgis_process and ogr2ogr)
#   * `osmium-tool`
#    ```
#    Windows:> conda install conda-forge::osmium-tool
#    ```
#
# 2. Download `.pbf` file from [http://download.geofabrik.de]
#
# 3. Configure variables below (QGIS_PATH, QGIS_PROCESS, OGR2OGR, OSMIUM)
#
# 4. Extract wanted target sub-area from `.pbf` (see bottom of this script)
#    ```
#    osmium extract -p czech-republic.poly europe-latest.osm.pbf, -o cz.pbf
#    osmium extract -p cz-sk.geojson europe-latest.osm.pbf, -o cz-sk.pbf
#    ```
#   * `.poly` files can be retrieved:
#     * From _raw directory index_ at [http://download.geofabrik.de], or
#     * By the following actions:
#       1. Get the OpenStreetMap relation from Nominatim
#         * Go to [nominatim.openstreetmap.org]
#         * Fill in country name
#         * Once found click on the link "(details)"
#         * In Details scroll down to "OSM: relation " and write down or copy the relation ID number
#           (CZ: 51684, SK: 14296)
#       2. Generate the polygon
#         * Go to [polygons.openstreetmap.fr]
#         * Fill in (or paste) the "OSM: relation" ID number you retrieved from Nominatim
#           for your desired country into the "Id of relation" field.
#         * This will create multiple polygons, consisting of 250 to 3500 nodes
#           (NPoints). The poly itself can be found in the "poly" column.
#           Choose the one with 400 nodes at maximum.
#         * In case there is no polygon with less then 400 nodes you will need to simplify the polygon (changing the X value).
#           The simpler the polygon, the faster the country map can be created.
#         * Optionally, you can merge two polygons in QGIS:
#           * Load geojson files with polygons
#           * Select all Features
#           * Select 'Layer/Toggle Editing' mode -> then 'Edit/Merge selected features'
#           * _Layer/Save as_ geojson
#
# 5. Run the script.
#   * **Notice:** Processing the 'city_area' layer for state-wide and larger
#                 areas can take several hours.
#
# Implementation notes:
# * osmium is much faster for data extractions then ogr2ogr or qgis
# * ogr2ogr is much faster for data conversions then qgis
# * ogr2ogr -simplify XXX does not work with -f "ESRI Shapefile",
#   -f "GeoJSON" must be used as an intermediate file
#
# ------------------------------------------------------------------------------

QGIS_PATH="/c/Program Files/QGIS 3.40.3"

OSMIUM=("tools/osmium")

# o4w_env.bat has problems with arguments containing a space, so we must use
# an ugly workaround below
#~ OGR2OGR=("$QGIS_PATH/OSGeo4W.bat" "ogr2ogr")
#~ QGIS_PROCESS=("$QGIS_PATH/OSGeo4W.bat" "qgis_process-qgis.bat")
OGR2OGR=(cmd.exe //C "echo" "off" "&&" call "$QGIS_PATH/bin/o4w_env.bat" "&&" "ogr2ogr")

QGIS_PROCESS=(cmd.exe //C "echo" "off" "&&" call "$QGIS_PATH/bin/o4w_env.bat" "&&" "qgis_process-qgis.bat")

TMP_DIR="tmp"

BASE_PBF="${TMP_DIR}/europe-latest.osm.pbf"
WORK_PBF="${TMP_DIR}/cz-sk.pbf"

export GDAL_DATA="tools/gdal-data"

# ------------------------------------------------------------------------------

# Print build header to stdout.
# $1 .. build title
function print_build {
  echo "============================================================================="
  echo "Building $1"
  echo "-----------------------------------------------------------------------------"
  echo
}

# ------------------------------------------------------------------------------

# Print step header to stdout.
# $1 .. step counter
function print_step {
  echo "--------------------------------------------------------------- step $1 ------"
}

# ------------------------------------------------------------------------------

# Remove fields from the data.
# LK8000 does'not use any fields for roads, railways etc.
# $1 .. input file
# $2 .. output file
# $3 .. ';' delimited list of existing field names
function remove_fields {
  local INP="$1"
  local OUT="$2"
  local FIELDS="$3"
  "${QGIS_PROCESS[@]}" run native:deletecolumn INPUT="${INP}" COLUMN="$FIELDS" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Computes a buffer area for all the features in an input layer, using a fixed or dynamic distance.
# $1 .. input file
# $2 .. output file
# $3 .. distance
# $4 .. controls the number of line segments to use to approximate a quarter circle when creating rounded offsets
function buffer_area {
  local INP="$1"
  local OUT="$2"
  local DISTANCE="$3"
  local SEGMENTS="$4"
  "${QGIS_PROCESS[@]}" run native:buffer INPUT="${INP}" DISTANCE="$DISTANCE" SEGMENTS="$SEGMENTS" END_CAP_STYLE=1 JOIN_STYLE=1 MITER_LIMIT=2 DISSOLVE=0 OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Combines their features into new features.
# $1 .. input file
# $2 .. output file
function dissolve {
  local INP="$1"
  local OUT="$2"
  "${QGIS_PROCESS[@]}" run native:dissolve INPUT="${INP}" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Removes holes in polygons.
# $1 .. input file
# $2 .. output file
# $3 .. remove holes with area less than
function delete_holes {
  local INP="$1"
  local OUT="$2"
  local MIN_AREA="$3"
  "${QGIS_PROCESS[@]}" run native:deleteholes INPUT="${INP}" MIN_AREA="$MIN_AREA" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Simplifies the geometries in a line or polygon layer.
# $1 .. input file
# $2 .. output file
# $3 .. method (0 - Douglas-Peucker, good for roads, 2 - Visvalingam-Whyatt, good for nature ponds etc.)
# $4 .. tolerance
function simplify {
  local INP="$1"
  local OUT="$2"
  local METHOD="$3"
  local TOLERANCE="$4"
  "${QGIS_PROCESS[@]}" run native:simplifygeometries INPUT="${INP}" METHOD="$METHOD" TOLERANCE="$TOLERANCE" OUTPUT="${OUT}"
  #"${OGR2OGR[@]}" -simplify "$TOLERANCE" -select "osm_id" -f "GeoJSON" "${TMP_BASE}.2.geojson" "${TMP_BASE}.1.pbf" lines
}

# ------------------------------------------------------------------------------

# Tessellates a polygon geometry layer, dividing the geometries into triangular components.
# $1 .. input file
# $2 .. output file
function tessellate {
  local INP="$1"
  local OUT="$2"
  "${QGIS_PROCESS[@]}" run 3d:tessellate INPUT="${INP}" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Creates a new vector layer that only contains matching features from an input layer.
# in which all geometries contain a single part.
# $1 .. input file
# $2 .. output file
# $3 .. selection attribute
# $4 .. operator (number): 0:=  1:<>  2:>  3:>=  4:<  5:<=  6:begins with  7:contains  8:is null  9:is not null  10:does not contain
# $5 .. value (string)
function extract_by_attribute {
  local INP="$1"
  local OUT="$2"
  local FIELD="$3"
  local OPERATOR="$4"
  local VALUE="$5"
  "${QGIS_PROCESS[@]}" run native:extractbyattribute INPUT="${INP}" FIELD="$FIELD" OPERATOR="$OPERATOR" VALUE="$VALUE" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Takes a vector layer with multipart geometries and generates a new one
# in which all geometries contain a single part.
# $1 .. input file
# $2 .. output file
function multipart2singleparts {
  local INP="$1"
  local OUT="$2"
  "${QGIS_PROCESS[@]}" run native:multiparttosingleparts INPUT="${INP}" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Create a valid representation of a given invalid geometry without losing
# any of the input vertices.
# $1 .. input file
# $2 .. output file
function fix_geometries {
  local INP="$1"
  local OUT="$2"
  "${QGIS_PROCESS[@]}" run native:fixgeometries INPUT="${INP}" METHOD=1 OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Add dummy field (shapefile .dbf file must have at least one field)
# $1 .. input file
# $2 .. output file
function set_dummy_field {
  local INP="$1"
  local OUT="$2"
  #~ cmd.exe //C call qgis_process-qgis.bat run native:fieldcalculator INPUT="${INP}" FIELD_NAME="x" FIELD_TYPE=2 FIELD_LENGTH=1 FORMULA="'x'" OUTPUT="${OUT}"
  "${QGIS_PROCESS[@]}" run native:fieldcalculator INPUT="${INP}" FIELD_NAME="x" FIELD_TYPE=6 FIELD_LENGTH=0 FORMULA="1" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Add calculated area field for polygons.
# $1 .. input file
# $2 .. output file
function set_area_field {
  local INP="$1"
  local OUT="$2"
  # we must tranform projection first so that the area is calculated in m2
  "${QGIS_PROCESS[@]}" run native:fieldcalculator INPUT="${INP}" FIELD_NAME="AREA" FIELD_TYPE=0 FIELD_LENGTH=0 FORMULA="area(transform(\$geometry, 'EPSG:4326','EPSG:3763'))" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Adds a new field for every given key in stored in the other_tags field.
# $1 .. input file
# $2 .. output file
# $3 .. expected list of fields separated by a comma (optional)
function explode_other_tags {
  local INP="$1"
  local OUT="$2"
  local FIELDS="$3"
  "${QGIS_PROCESS[@]}" run native:explodehstorefield INPUT="${INP}" FIELD="other_tags" EXPECTED_FIELDS="$FIELDS" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Combines multiple vector layers of the same geometry type into a single one.
# $1 .. input layer 1
# $2 .. input layer 2
# $3 .. output file
# $4 .. CRS of the output; if not specified, the CRS will be taken from the first input layer
function merge_layers_2 {
  local INP1="$1"
  local INP2="$2"
  local OUT="$3"
  local CRS="$4"
  "${QGIS_PROCESS[@]}" run native:mergevectorlayers LAYERS="${INP1}" LAYERS="${INP2}" CRS="$CRS" OUTPUT="${OUT}"
}

# ------------------------------------------------------------------------------

# Save shapefile
# $1 .. input file
# $2 .. output dir
# $3 .. output name (without any extension)
function export_shp {
  local INP="$1"
  local OUT="$2"
  local NAME="$3"

  # QGIS_PROCESS does not work - ENCODING="UTF-8" is used for input only
  #"${QGIS_PROCESS[@]}"  run native:savefeatures INPUT="${INP}" ENCODING="UTF-8" OUTPUT="${OUT}/${NAME}.shp"

  "${OGR2OGR[@]}" -nln "$NAME" -f "ESRI Shapefile" "${OUT}" "${INP}" -lco "ENCODING=UTF-8" -overwrite
}

# ------------------------------------------------------------------------------

# Not used - LK8000 is slow with railways built as areas.
# Maybe because of plygons with large extent. We could try to cut them into
# smaller pieces. But Lk8000 works with many lines just fine.
#
# Process railways.
# $1 .. output file name
# $2-$x .. osmium tags-filter (multiple arguments create join)
#function build_railways {
#  local OUT_NAME="$1"
#  shift
#  local PROC_DIR="$TMP_DIR/$OUT_NAME"
#  local TMP_BASE="${PROC_DIR}/tmp"
#  local SHP_DIR="${PROC_DIR}/shp"
#
#  print_build "$OUT_NAME"
#
#  rm -fR "$PROC_DIR"/*
#
#  mkdir -p "$PROC_DIR" "$SHP_DIR"
#
#  "${OSMIUM[@]}" tags-filter "${WORK_PBF}" "$@" -t -o "${TMP_BASE}.1.pbf"
#  #"${OSMIUM[@]}"  export --geometry-types=linestring "${TMP_BASE}.1.pbf" -o "${TMP_BASE}.2.geojson"
#
#  "${OGR2OGR[@]}" -select "osm_id" -f "GeoJSON" "${TMP_BASE}.2.gpkg" "${TMP_BASE}.1.pbf" lines
#
#  buffer_area "${TMP_BASE}.1.gpkg" "${TMP_BASE}.2.gpkg" "0.0001" "5"
#
#  dissolve "${TMP_BASE}.2.gpkg" "${TMP_BASE}.3.gpkg"
#
#  delete_holes "${TMP_BASE}.3.gpkg" "${TMP_BASE}.4.gpkg" "0.00001"
#
#  simplify "${TMP_BASE}.4.gpkg" "${TMP_BASE}.5.gpkg" 2 "0.0003"
#
#  tessellate "${TMP_BASE}.5.gpkg" "${TMP_BASE}.6.gpkg"
#
#  # add some short dummy field, because .dbf file must have at least one field
#  set_dummy_field "${TMP_BASE}.6.gpkg" "${TMP_BASE}.7.gpkg"
#
#  # remove other fields so that .dbf file has minimum size
#  remove_fields "${TMP_BASE}.7.gpkg" "${TMP_BASE}.8.gpkg" "osm_id;fid"
#
#  export_shp "${TMP_BASE}.8.gpkg" "${SHP_DIR}" "${OUT_NAME}"
#}


# ------------------------------------------------------------------------------

# Process lines (roads, railways, rivers, power lines).
# $1 .. output file name
# $2-$x .. osmium tags-filter (multiple arguments create join)
function build_lines {
  local OUT_NAME="$1"
  shift
  local PROC_DIR="$TMP_DIR/$OUT_NAME"
  local TMP_BASE="${PROC_DIR}/tmp"
  local SHP_DIR="${PROC_DIR}/shp"

  print_build "$OUT_NAME"

  rm -fR "$PROC_DIR"/*

  mkdir -p "$PROC_DIR" "$SHP_DIR"

  local STEP_IN=0
  local STEP_OUT=0
  local STEP_INPUT='${TMP_BASE}.${STEP_IN}.${PEXT}'
  local STEP_OUTPUT='${TMP_BASE}.${STEP_OUT}.${PEXT}'
  local PEXT="fgb"

  print_step $((++STEP_OUT)) #1
  "${OSMIUM[@]}" tags-filter "${WORK_PBF}" "$@" -t -o "${TMP_BASE}.${STEP_OUT}.pbf"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #2
  "${OGR2OGR[@]}" -select "osm_id" "${STEP_OUTPUT@P}" "${TMP_BASE}.${STEP_IN}.pbf" lines

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #3
  simplify "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "0" "0.0002"

  # add some short dummy field, because .dbf file must have at least one field
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #4
  set_dummy_field "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # remove other fields so that .dbf file has minimum size
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #5
  remove_fields "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "osm_id;fid"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #6
  export_shp "${STEP_INPUT@P}" "${SHP_DIR}" "${OUT_NAME}"
}

# ------------------------------------------------------------------------------

# Process areas (cities, lakes, forests).
# $1 .. [city|water|forest]
# $2 .. output file name
# $3-$x .. osmium tags-filter (multiple arguments create join)
function build_areas {
  local TYPE="$1"
  local OUT_NAME="$2"
  shift 2
  local PROC_DIR="$TMP_DIR/$OUT_NAME"
  local TMP_BASE="${PROC_DIR}/tmp"
  local SHP_DIR="${PROC_DIR}/shp"

  print_build "$OUT_NAME as $TYPE"

  local KEEP_FIELD
  local BUFFER_DISTANCE
  local HOLES_AREA_THR=
  local SIMPLIFY_THR
  local MIN_AREA

  case "$TYPE" in
    "city")
      KEEP_FIELD=""
      BUFFER_DISTANCE="0.0005"
      HOLES_AREA_THR="0.001"
      SIMPLIFY_THR="0.002"
      MIN_AREA="270000"
      ;;
    "water")
      # dissolve discards fields, so the only option to show lake names
      # in LK8000 would be creating point layer with lake names only
      #KEEP_FIELD="name"
      KEEP_FIELD=""
      BUFFER_DISTANCE="0.0001"
      HOLES_AREA_THR="0.0001"
      SIMPLIFY_THR="0.001"
      MIN_AREA="30000"
      ;;
    "forest")
      KEEP_FIELD=""
      BUFFER_DISTANCE="0.0001"
      HOLES_AREA_THR="0.001"
      SIMPLIFY_THR="0.002"
      MIN_AREA="270000"
      ;;
    *)
      echo "invalid type='$TYPE' for build_areas"
      exit 1;
      ;;
  esac

  rm -fR "$PROC_DIR"/*

  mkdir -p "$PROC_DIR" "$SHP_DIR"

  local STEP_IN=0
  local STEP_OUT=0
  local STEP_INPUT='${TMP_BASE}.${STEP_IN}.${PEXT}'
  local STEP_OUTPUT='${TMP_BASE}.${STEP_OUT}.${PEXT}'
  # we use gpkg because writing fgb ends with "NULL geometry not supported with spatial index" after de-buffering in step 7
  local PEXT="gpkg"

  print_step $((++STEP_OUT)) #1
  "${OSMIUM[@]}" tags-filter "${WORK_PBF}" "$@" -t -o "${TMP_BASE}.${STEP_OUT}.pbf"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #2
  "${OGR2OGR[@]}" -select "osm_id,$KEEP_FIELD" "${STEP_OUTPUT@P}" "${TMP_BASE}.${STEP_IN}.pbf" multipolygons

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #3
  buffer_area "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "$BUFFER_DISTANCE" "2"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #4
  dissolve "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #5
  delete_holes "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "$HOLES_AREA_THR"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #6
  multipart2singleparts "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "0.001"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #7
  buffer_area "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "-$BUFFER_DISTANCE" "2"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #8
  simplify "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" 2 "$SIMPLIFY_THR"

  # add calculated area field for polygons
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #9
  set_area_field "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # filter polygons with area greater than x
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #10
  extract_by_attribute "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "AREA" "2" "$MIN_AREA"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #11
  fix_geometries "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # add some short dummy field, because .dbf file must have at least one field
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #12
  set_dummy_field "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # remove other fields so that .dbf file has minimum size
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #13
  remove_fields "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "osm_id;fid;area"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #14
  export_shp "${STEP_INPUT@P}" "${SHP_DIR}" "${OUT_NAME}"
}

# ------------------------------------------------------------------------------

# Process areas and create hatched areas from lines (good for forests).
# $1 .. [forest]
# $2 .. output file name
# $3 .. input shape file
function build_hatched_areas {
  local TYPE="$1"
  local OUT_NAME="$2"
  local INP_FILE="$3"

  local PROC_DIR="$TMP_DIR/$OUT_NAME"
  local TMP_BASE="${PROC_DIR}/tmp"
  local SHP_DIR="${PROC_DIR}/shp"

  print_build "$OUT_NAME as $TYPE"

  local HATCH_SPACING

  case "$TYPE" in
    "forest")
      HATCH_SPACING="1000"
      ;;
    *)
      echo "invalid type='$TYPE' for build_hatched_areas"
      exit 1;
      ;;
  esac

  rm -fR "$PROC_DIR"/*

  mkdir -p "$PROC_DIR" "$SHP_DIR"

  local STEP_IN=0
  local STEP_OUT=0
  local STEP_INPUT='${TMP_BASE}.${STEP_IN}.${PEXT}'
  local STEP_OUTPUT='${TMP_BASE}.${STEP_OUT}.${PEXT}'
  local PEXT="fgb"

  # create border lines from polygons
  print_step $((++STEP_OUT)) #1
  "${QGIS_PROCESS[@]}" run native:polygonstolines INPUT="${INP_FILE}" OUTPUT="${STEP_OUTPUT@P}"
  local BORDER_LINES="${STEP_OUTPUT@P}"

  # create bounding box of all areas (we will use it as an extent for the created lines)
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #2
  "${QGIS_PROCESS[@]}" run qgis:minimumboundinggeometry INPUT="${STEP_INPUT@P}" TYPE=0 OUTPUT="${STEP_OUTPUT@P}"

  # extend box so that after rotating hatch line  they will still cover all the area features
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #3
  buffer_area "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "8" "2"

  # create line hatching with lines 50m apart, cover the area from previous step,
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #4
  "${QGIS_PROCESS[@]}" run native:creategrid TYPE=1 EXTENT="${STEP_INPUT@P}" HSPACING="$HATCH_SPACING" VSPACING=1000 CRS="EPSG:3857" OUTPUT="${STEP_OUTPUT@P}"

  # calculate line angle, so that we can extract vertical lines only
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #5
  "${QGIS_PROCESS[@]}" run native:fieldcalculator INPUT="${STEP_INPUT@P}" FIELD_NAME="ANGLE" FIELD_TYPE=0 FIELD_LENGTH=0 FORMULA="main_angle(\$geometry)" OUTPUT="${STEP_OUTPUT@P}"

  # extract vertical lines only
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #6
  extract_by_attribute "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "ANGLE" 0 180

  # rotate lines in 45 degrees
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #7
  "${QGIS_PROCESS[@]}" run native:rotatefeatures INPUT="${STEP_INPUT@P}" ANGLE=45 OUTPUT="${STEP_OUTPUT@P}"

  # clip hatching to area of polygons
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #8
  "${QGIS_PROCESS[@]}" run native:clip INPUT="${STEP_INPUT@P}" OVERLAY="${INP_FILE}" OUTPUT="${STEP_OUTPUT@P}"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #9
  merge_layers_2 "${BORDER_LINES}" "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # add some short dummy field, because .dbf file must have at least one field
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #10
  set_dummy_field "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # remove other fields so that .dbf file has minimum size
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #11
  remove_fields "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "ANGLE"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #12
  export_shp "${STEP_INPUT@P}" "${SHP_DIR}" "${OUT_NAME}"
}

# ------------------------------------------------------------------------------

# Build named points from area names (good for lake names).
# $1 .. [water]
# $2 .. output file name
# $3-$x .. osmium tags-filter (multiple arguments create join)
function build_area_points {
  local TYPE="$1"
  local OUT_NAME="$2"
  shift 2
  local PROC_DIR="$TMP_DIR/$OUT_NAME"
  local TMP_BASE="${PROC_DIR}/tmp"
  local SHP_DIR="${PROC_DIR}/shp"

  print_build "$OUT_NAME as $TYPE"

  local MIN_AREA

  case "$TYPE" in
    "water")
      MIN_AREA="100000"
      ;;
    *)
      echo "invalid type='$TYPE' for build_area_points"
      exit 1;
      ;;
  esac

  rm -fR "$PROC_DIR"/*

  mkdir -p "$PROC_DIR" "$SHP_DIR"

  local STEP_IN=0
  local STEP_OUT=0
  local STEP_INPUT='${TMP_BASE}.${STEP_IN}.${PEXT}'
  local STEP_OUTPUT='${TMP_BASE}.${STEP_OUT}.${PEXT}'
  local PEXT="fgb"

  print_step $((++STEP_OUT)) #1
  "${OSMIUM[@]}" tags-filter "${WORK_PBF}" "$@" -t -o "${TMP_BASE}.${STEP_OUT}.pbf"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #2
  "${OGR2OGR[@]}" -select "osm_id,name" "${STEP_OUTPUT@P}" "${TMP_BASE}.${STEP_IN}.pbf" multipolygons

  # filter polygons with known name
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #3
  extract_by_attribute "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "name" "9"

  # add calculated area field for polygons
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #4
  set_area_field "${STEP_INPUT@P}" "${STEP_OUTPUT@P}"

  # filter polygons with area greater than x
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #5
  extract_by_attribute "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "AREA" "2" "$MIN_AREA"

  # calculate points inside the polygons
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #6
  "${QGIS_PROCESS[@]}" run native:pointonsurface INPUT="${STEP_INPUT@P}" OUTPUT="${STEP_OUTPUT@P}"

  # remove other fields so that .dbf file has minimum size
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #7
  remove_fields "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "osm_id;AREA"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #8
  export_shp "${STEP_INPUT@P}" "${SHP_DIR}" "${OUT_NAME}"
}


# ------------------------------------------------------------------------------

# Process points (cities, towns, villages).
# $1 .. [city|town|village]
# $2 .. output file name
# $3-$x .. osmium tags-filter (multiple arguments create join)
function build_points {
  local TYPE="$1"
  local OUT_NAME="$2"
  shift 2
  local PROC_DIR="$TMP_DIR/$OUT_NAME"
  local TMP_BASE="${PROC_DIR}/tmp"
  local SHP_DIR="${PROC_DIR}/shp"

  print_build "$OUT_NAME as $TYPE"

  local ATTR_FILTER

  case "$TYPE" in
    "city")
      ATTR_FILTER=""
      ;;
    "town")
      ATTR_FILTER=""
      ;;
    "village")
      ATTR_FILTER=""
      ;;
    # we will use 'Smaller cities' layer for power lines.
    #"village")
    #  ATTR_FILTER=("population" "2" "300") #>
    #  ;;
    #"smallvillage")
    #  ATTR_FILTER=("population" "5" "300") #<=
    #  ;;
    *)
      echo "invalid type='$TYPE' for build_points"
      exit 1;
      ;;
  esac

  rm -fR "$PROC_DIR"/*

  mkdir -p "$PROC_DIR" "$SHP_DIR"

  local STEP_IN=0
  local STEP_OUT=0
  local STEP_INPUT='${TMP_BASE}.${STEP_IN}.${PEXT}'
  local STEP_OUTPUT='${TMP_BASE}.${STEP_OUT}.${PEXT}'
  local PEXT="fgb"

  print_step $((++STEP_OUT)) #1
  "${OSMIUM[@]}" tags-filter "${WORK_PBF}" "$@" -o "${TMP_BASE}.${STEP_OUT}.pbf"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #2
  "${OGR2OGR[@]}" -select "osm_id,name,other_tags" "${STEP_OUTPUT@P}" "${TMP_BASE}.${STEP_IN}.pbf" points

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #3
  explode_other_tags "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "population"

  if [[ "$ATTR_FILTER" != "" ]]; then
    # filter points depending on the filter
    STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #4
    extract_by_attribute "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "${ATTR_FILTER[@]}"
  fi

  # remove other fields so that .dbf file has minimum size
  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #4/5
  remove_fields "${STEP_INPUT@P}" "${STEP_OUTPUT@P}" "osm_id;other_tags;population"

  STEP_IN=$STEP_OUT; print_step $((++STEP_OUT)) #5/6
  export_shp "${STEP_INPUT@P}" "${SHP_DIR}" "${OUT_NAME}"
}

# ------------------------------------------------------------------------------

# Save topology.tpl with layers configuration.
# The layers are displayed in the order of the lines - the layer on the last
# line is shown as the topmost.
# The water must be shown above city_area.
# Format:
#   * filename,type,icon,field,red,green,blue
#   * type > 5000: new LK800 topology definition:
#   * 5000 reserved
#   * 5001 marked locations
#   * 5005 coast areas,     default range=100
#   * 5010 water area,      default range=100
#   * 5020 water line,      default range=7
#   * 5030 big road,        default range=25
#   * 5040 medium road,     default range=6
#   * 5050 small road,      default range=3
#   * 5060 railroad,        default range=8
#   * 5070 big city,        default range=15
#   * 5080 medium city,     default range=10
#   * 5090 small city,      default range=6
#   * 5100 very small city, default range=3
#   * 5110 city area polyline with no name, default range=15
#   * type < 5000: range (legacy topology, zoom threshold configuration in LK8000 is ignored)
#   * range: defines zoom level when the layer becomes visible
#   *
#   * field: denotes field index in .dbf file with the name of the feature
#   * red=64,green=96,blue=240 is replaced with ICAO standard water color
#
# $1 .. output file
function save_topology_tpl {
  local OUT_FILE="$1"

# Legcy LK8000 topology (fine-tuned zoom ranges)
cat >"$OUT_FILE" <<EOD
* The layers are displayed in the order of the lines - the layer on the last
* line is shown as the topmost.
*
* If you would like to remove some layer (forests or power lines), prepend
* the corresponding line with an asterisk.
*
* Notice:
* This map package contains overhead power lines layer (power_line).
* In LK8000 configuration use the 'Smaller cities' in the LK8000 setup page 4,
* to configure the zoom range for the power lines.
*
* New LK8000 topology (user configurable zoom ranges, bold highways)
*
* Format: filename,zoom_range,icon,name_field,red,green,blue

forest_area,              5080,,,0,180,0
city_area,                5110,,,223,223,0
water_area,               5010,,,64,96,240
water_line,               5020,,,64,96,240
roadbigconstruction_line, 5030,,,254,210,120
roadsmall_line,           5050,,,205,142,56
roadmedium_line,          5040,,,230,77,0
roadbig_line,             5030,,,255,95,17
railroad_line,            5060,,,64,64,64
power_line,               5100,,,194,140,255
water_point,              5090,502,1,64,96,240
citybig_point,            5070,218,1,223,223,0
citymedium_point,         5080,501,1,223,223,0
citysmall_point,          5090,502,1,223,223,0

* The following part uses the legacy format for zoom ranges fine tuning,
* (mainly for power lines and forests).
* As a result, if used, the zoom user configuration (on page 4) will be ignored,
* and highways will not be drawn with a bold line.
* If you want bold highways, or configure topology from LK8000, use the first
* part of the configuration (prepend the following lines with an asterisk and
* remove the asterisk from the lines at the very top, and vice versa).

*forest_area,              10,,,0,180,0
*city_area,                15,,,223,223,0
*water_area,               99,,,64,96,240
*water_line,                7,,,64,96,240
*roadbigconstruction_line,  8,,,254,210,120
*roadsmall_line,            3,,,205,142,56
*roadmedium_line,           6,,,230,77,0
*roadbig_line,             25,,,255,95,17
*railroad_line,             8,,,64,64,64
*power_line,              0.5,,,194,140,255
*water_point,               3,502,1,64,96,240
*citybig_point,            15,218,1,223,223,0
*citymedium_point,         10,501,1,223,223,0
*citysmall_point,           3,502,1,223,223,0

EOD

#cityverysmall_point,      5100,502,1,223,223,0

#roadbig_line, 5030,,,240,64,64
#roadmedium_line, 5040,,,240,64,64
#roadsmall_line, 5050,,,240,64,64

#roadbig_line,             5030,,,153,51,0
#roadbigconstruction_line, 5030,,,255,178,67
#roadmedium_line,          5040,,,230,77,0
#roadsmall_line,           5050,,,255,119,51

#coast_area,               5005,,,64,96,240
#sea_area,                 5005,,,64,96,240
#object_point,             5100,502,1,51,102,0
#obstacles_point,          5100,501,218,255,0,0
}

# ------------------------------------------------------------------------------

mkdir -p "$TMP_DIR"

#~ "${QGIS_PROCESS[@]}" help native:rotatefeatures

#~ curl "http://download.geofabrik.de/europe/czech-republic.poly" -o "${TMP_DIR}/czech-republic.poly"
#~ curl "http://download.geofabrik.de/europe/slovakia.poly" -o "${TMP_DIR}/slovakia.poly"

curl "http://download.geofabrik.de/europe-latest.osm.pbf" -o "${BASE_PBF}"
"${OSMIUM[@]}" extract -p area-cz-sk.geojson "${BASE_PBF}" -o "${WORK_PBF}"

#TEST_PBF="${TMP_DIR}/test.pbf"
#"${OSMIUM[@]}" extract -p area-test.geojson "${WORK_PBF}" -o "${TEST_PBF}"
#WORK_PBF="$TEST_PBF"

build_lines "railroad_line" "w/railway=rail"

build_lines "roadbig_line" "w/highway=motorway,trunk"

# as 'w/highway=construction' returns also secondary and tertiary ways, we will use 'w/construction=motorway,trunk' filter
build_lines "roadbigconstruction_line" "w/construction=motorway,trunk"

build_lines "roadmedium_line" "w/highway=primary,motorway_link,trunk_link,primary_link,secondary_link,motorway_junction"

build_lines "roadsmall_line" "w/highway=secondary,tertiary" # residential,service

build_lines "water_line" "w/waterway=river,tidal_channel,canal" # stream

build_lines "power_line" "w/power=line,minor_line"

build_areas "city" "city_area" "wr/building=*" "wr\amenity=*" "wr/landuse=residential,administrative,construction,industrial,religious,retail,school,garages,brownfield,cemetery,depot,recreation_ground,village_green,park,commercial,allotments"

build_areas "water" "water_area" "wr/natural=water"

build_area_points "water" "water_point" "wr/natural=water"

build_areas "forest" "forest_area_fill" "wr/landuse=forest" "wr/natural=forest"
build_hatched_areas "forest" "forest_area" "${TMP_DIR}/forest_area_fill/shp/forest_area_fill.shp"

build_points "city"         "citybig_point"       "n/place=city"
build_points "town"         "citymedium_point"    "n/place=town"
build_points "village"      "citysmall_point"     "n/place=village"


save_topology_tpl "${TMP_DIR}/topology.tpl"

zip -j "${TMP_DIR}/CZ-SK-2025.lkm"    \
  "${TMP_DIR}/topology.tpl"           \
  "${TMP_DIR}/railroad_line/shp"/*    \
  \
  "${TMP_DIR}/roadbig_line/shp"/*     \
  "${TMP_DIR}/roadbigconstruction_line/shp"/* \
  "${TMP_DIR}/roadmedium_line/shp"/*  \
  "${TMP_DIR}/roadsmall_line/shp"/*   \
  \
  "${TMP_DIR}/city_area/shp"/*        \
  "${TMP_DIR}/citybig_point/shp"/*    \
  "${TMP_DIR}/citymedium_point/shp"/* \
  "${TMP_DIR}/citysmall_point/shp"/*  \
  \
  "${TMP_DIR}/power_line/shp"/*       \
  "${TMP_DIR}/forest_area/shp"/*      \
  \
  "${TMP_DIR}/water_line/shp"/*       \
  "${TMP_DIR}/water_area/shp"/*       \
  "${TMP_DIR}/water_point/shp"/*
