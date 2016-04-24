name := "OSM tag processor"

version := "0.0.1"

scalaVersion := "2.11.7"

libraryDependencies += "org.apache.spark" %% "spark-core" % "1.6.1"

libraryDependencies += "org.apache.spark" %% "spark-sql" % "1.6.1"

libraryDependencies += "org.scalatest" %% "scalatest" % "2.2.1" % "test"

libraryDependencies += "com.holdenkarau" %% "spark-testing-base" % "1.6.1_0.3.3"

libraryDependencies += "com.databricks" % "spark-csv_2.11" % "1.2.0"

// See:
//   https://github.com/holdenk/spark-testing-base
//
javaOptions ++= Seq("-Xms512M", "-Xmx2048M", "-XX:MaxPermSize=2048M", "-XX:+CMSClassUnloadingEnabled")
