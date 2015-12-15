The below explains how to extract the data necessary to create the visualizations
from an OpenStreetMap full export.

**NOTE:** These instructions assume familiarity with cloud services like
the AWS. In particular, please be aware that following the below instructions
will incur costs, and these might be significant if resources are
not properly shut down after use.

## Step 1: Start a server

The below instructions are written for an AWS m3.medium instance running
a 64 bit Ubuntu Server 14.04 (Trusty) LTS.

The full OpenStreetMap export is around 50GB (as a pbf file), and the exported
data will be around 1-2GB. To fit this data on disk, it is necessary to attach
an additional volume (say a 65GB general purpose SSD) to the instance.
Instructions for doing this can be found [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html).

## Step 2: Download the latest OSM data

We will need the latest export that include the full edit
history of the OpenStreetMap data. This is available both as an osm.bz2 file (c. 70G as of 12/2015)
and as an osm.pbf file (c. 50G). We will use the osm.pbf file as this is
faster to process.

In addition to the [main server](http://planet.openstreetmap.org/planet/full-history/),
there are a number of [mirrors](http://wiki.openstreetmap.org/wiki/Planet.osm) hosting
these exports. These are updated weekly. Download as:

```
wget http://<<server name>/history-151207.osm.pbf.md5   
wget http://<<server name>/history-151207.osm.pbf
```

This can take around 20 minutes.

## Step 3: Extract data

Install tools needed by the extraction tool:

```
sudo apt-get update
sudo apt-get install git zip nodejs-legacy npm
npm install osmium js-string-escape
```

Make a directory for the extracted data (on the attached volume with disk space):

```
mkdir osm-data-2015-12-07
```

After this, we are ready to download and run the extraction tool:

```
git clone https://github.com/matiasdahl/osm-extract-amenities.git
cd osm-extract-amenities
nohup ./extract-amenities ../history-151207.osm.pbf ../osm-data-2015-12-07/ &
```

The above will take around 11 hours on a m3.medium instance (Intel Xeon(R) CPU E5-2670
at 2.50GHz, 3.5GB memory).

After the script is finished, the output directory `osm-data-2015-12-07/` will
contain a number of files about timing and files listing characteristics of the
underlying system. The directory also contains the md5 checksum computed from
the input file. This should match the downloaded md5 checksum, see above.

## Step 4: Create a zip file with the extracted data

Add a `LICENSE` file in the output directory that describes how the data was
extracted and its license. For example:

```
The txt files in this zip-file are extracted from the full OpenStreetMap export
from 07.12.2015 (history-151207.osm.pbf, md5: 66138484ec06cfb92532a6fb5d82abea).
This data is (c) OpenStreetMap contributors and distributed under the ODbL. See:

   https://www.openstreetmap.org/copyright

For further information how the data was extracted, see:

   https://github.com/matiasdahl/osm-tag-dynamics
   https://github.com/matiasdahl/osm-extract-amenities

A zip:ed snapshot of the second git repository (that contains the extraction
script) is included.
```

Of the output files, we only need `amenities-nodes.txt` (c. 900M),
`amenities-ways.txt` (c. 450M) and `amenities-relations.txt` (c. 5M). The below
zips these, the license file, and a snapshot of the repository with
the extraction script:

```
# in the directory with the output files:
zip -9 -r osm-extract-amenities-snapshot.zip ../osm-extract-amenities
zip -9 osm-extract-2015-12-07.zip *.txt LICENSE osm-extract-amenities-snapshot.zip
```

The above step will take around 5 minutes and the final zip file will be around 350M.

## Step 5: Commit the zip file

```
# TODO: - install github's lfs extension

git clone https://github.com/matiasdahl/osm-tag-dynamics.git

# TODO: - add osm-extract-2015-12-07.zip to the `osm-data/exports`-directory
# TODO: - ensure that the file is treated as an lfs file

git commit -m "Added: osm-extract-2015-12-07.zip"
git push
```

## Step 6: Clean up

Stop and shutdown all resources on the AWS.
