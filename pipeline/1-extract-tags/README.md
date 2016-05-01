The below explains how to extract the data necessary to create the visualizations from an OpenStreetMap full export. This is the first step in the pipeline. An earlier version of this extraction script can be found in [this repo](https://github.com/matiasdahl/osm-extract-amenities).

**NOTE:** These instructions assume familiarity with cloud services like the AWS. In particular, please be aware that following the below instructions will incur costs, and these might be significant if resources are not properly shut down after use.

## Step 1: Start a server

The below instructions are written for an AWS m3.medium (1 vCPU, 3.75G memory) instance running a 64 bit Ubuntu Server 14.04 (Trusty) LTS.

The full OpenStreetMap export is around 50GB (as a pbf file as of 4/2016), and the exported data will be around 40GB as csv files. Compressed, the exported data is around 5G. To work with this data it is necessary to add more diskspace than is provided by default (say, a 150GB general purpose SSD) to the instance. Launching an instance and adjusting disk space can be done using the AWS web-console.

## Step 2: Download the latest OSM data

We will need the latest export that include the full edit history of the OpenStreetMap data. This is available both as an osm.bz2 file (c. 70G as of 4/2016) and as an osm.pbf file (c. 50G). We will use the osm.pbf file as this is faster to process.

In addition to the [main server](http://planet.openstreetmap.org/planet/full-history/), there are a number of [mirrors](http://wiki.openstreetmap.org/wiki/Planet.osm) hosting these exports. These are updated weekly. Download as:

```
wget http://<<server name>/history-151207.osm.pbf.md5   
wget http://<<server name>/history-151207.osm.pbf
```

For example

```
wget http://ftp.heanet.ie/mirrors/openstreetmap.org/pbf/full-history/history-160328.osm.pbf.md5
wget http://ftp.heanet.ie/mirrors/openstreetmap.org/pbf/full-history/history-160328.osm.pbf
```

This can take around 20 minutes.

## Step 3: Extract data

Install tools needed by the extraction tool:

```
sudo apt-get update
sudo apt-get install git zip mg nodejs-legacy npm
npm install osmium js-string-escape underscore
```

Make a directory for the extracted data:

```
mkdir osm
```

After this, we need to copy the extraction script into the above directory. From the `osm-tag-dynamics` repository we need the following scripts:

```
wget https://raw.githubusercontent.com/matiasdahl/osm-tag-dynamics/support-more-tags/pipeline/1-extract-tags/extract-tags.js
wget https://raw.githubusercontent.com/matiasdahl/osm-tag-dynamics/support-more-tags/pipeline/1-extract-tags/extract-tags
chmod u+x extract-tags
```

After this we can start the extraction:

```
nohup ./extract-tags ../history-151207.osm.pbf ./ &
```

The above will take around 40 hours on a m3.medium instance (Intel Xeon(R) CPU E5-2670 at 2.50GHz, 3.5GB memory).

After the script is finished, the output directory `osm-export/` will contain a number of files about timing and files listing characteristics of the underlying system. The directory also contains the md5 checksum computed from the input file. This should match the downloaded md5 checksum.

## Step 4: Create a zip file with the extracted data

Add a `LICENSE` file in the output directory that describes how the data was extracted and its license. For example:

```
The txt files in this zip-file are extracted from the full OpenStreetMap export
from 28.3.2016 (history-160328.osm.pbf, md5: 56ef96939be159afb41b951d0cf9c83e).
This data is (c) OpenStreetMap contributors and distributed under the ODbL. See:

   https://www.openstreetmap.org/copyright
   
The extraction scripts (extract-tags and extract-tags.js) used for creating 
the above txt files are also included in this zip file.

Files:
d938bab5fd2feef7a986aad9a4cdb774  nodes.txt (4.3G)
33cc8a86b30630f398e2328f2965a8f2  relations.txt (164M)
0b1dbefb93194f3797b3d7b215af58b5  ways.txt (33G)

For further information how the data was extracted, see:

   https://github.com/matiasdahl/osm-tag-dynamics
   https://github.com/matiasdahl/osm-extract-amenities

```

Of the output files, we only need `nodes.txt` (c. 4.3G), `ways.txt` (c. 33G) and `relations.txt` (c. 164M). The below zips these, the license file, and a snapshot of the repository with the extraction script:

```
zip -9 osm-extract-2016-03-16.zip README extract-tags* *.txt
```

The above step will take around (todo) minutes and the final zip file will be around 5.2G.

## Step 5: Stash the extracted data

Copy to S3, or copy to a more powerful computer depending on setup. 

## Step 6: Clean up

Stop and shutdown all resources on the AWS.

# License

MIT (extraction script+this documentation)