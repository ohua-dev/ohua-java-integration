{-
When eta compiles the project it creates an executable (ohua-dummy-main) which is a shell script
that contains (among other things) a listing of all dependency jar's for the ohua compiler.
This script is used to read that script and extract the list of dependencies, extract their paths
to a portable form.
Finally it reads the project.clj template and pastes the extracted jars as resources into the
project.clj template at the marker location and prepends a notice that the file is generated
-}

{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Text as T
import qualified Data.Text.IO as T
import Data.Maybe
import Data.Function
import Control.Applicative
import Data.Monoid ((<>))
import Control.Category ((>>>))

beginMarker = "$ETA_JAVA_CMD $JAVA_ARGS $JAVA_OPTS $ETA_JAVA_ARGS -classpath \"$DIR/ohua-dummy-main.jar:"
endMarker = ":$ETA_CLASSPATH\""
depInsertMarker = "(- insert-jar-deps -)"
projectFile = "project.clj"
templatePrefix = "template."
templateFile = templatePrefix <> projectFile
notice = T.append "; " $ T.intercalate "\n; "
    [ "NOTICE This file is generated by GenProjectClj.hs."
    , "Do not modify this file as changes will be overwritten when the file is regenerated."
    , "Commit your changes to the " <> T.pack templateFile <> " file instead."
    , "Furthermore please make sure you do not remove or alter the insertion marker \"" <> depInsertMarker <> "\""
    , "in the template file."
    ]


-- | Extract the list of jar deps from the input file
extract
    =   snd . T.breakOn beginMarker
    >>> fromMaybe (error "marker did not start string") . T.stripPrefix beginMarker
    >>> fst . T.breakOn endMarker
    >>> T.splitOn ":"

main = do
    deps <- T.intercalate " "
            . map (\t -> '"' `T.cons` t `T.snoc` '"')
            . extract
            <$> T.readFile "dist/build/ohua-dummy-main/ohua-dummy-main"
    template <- T.readFile templateFile
    T.writeFile projectFile $ T.intercalate deps (T.splitOn depInsertMarker template) `T.snoc` '\n' <> notice
