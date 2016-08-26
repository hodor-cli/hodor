
# Hodor: #### __We'll be the brawn, you be the brains.__
***

Introduction
===============
Hodor is a ruby-based framework, API and Command Line Interface that automates and simplifies the way you specify, deploy, debug and administer Hadoop and Oozie solutions. Why did we write Hodor? Because we recognized that the Hadoop ecosystem was missing something essential. While the creators of the Hadoop ecosystem have provided a cutting-edge data ingestion, storage, and transformation engine that performs well in production when provided a specific, fully debugged workflow, getting there is hard. Hadoop lacks a mature toolchain to manage a codebase with modern software development discipline. Enter Hodor: a combination of tools and conventions to address these shortcomings, by enabling in the Hadoop environment many of the software development practices, and deployment facilities we take for granted in normal software development.

Background
===============
The Hodor framework and CLI grew out of developer necessity: we needed a developer-oriented commandline alternative to the analyst-oriented Hue web interface tool. After working with Apache's Hue web interface, we quickly realized this tool was not designed to facilitate construction of the kind of production data systems we are building. We found no good alternative to Hue compatible with modern software development practice. Dumping Hue forced us to answer several important process questions. Without Hue, how would we manage production deployments? How should we build solutions that could be commited and reviewed in a version control system? How should we specify and structure Oozie workflows conforming to Oozie's data dependency architecture? How should we submit and monitor job status? As we began to answer these questions for ourselves, Hodor began to take shape.

Getting Help
============
Hodor includes a rich help system that can be separated into overview, detail and topic help pages. For example, here are a few help and topic commands that provide a sprectrum of depth, from overview to conceptual tutorials.

```bash
$ hodor                                 # Prints generation information about Hodor
$ hodor -T                              # Prints a more detail overview of Hodor's namespaces and commands
$ hodor help oozie                      # Prints an overview of the Oozie namespace, its purpose and commands
$ hodor help oozie:display_job          # Prints detailed information about the display_job command, arguments and options
$ hodor oozie:topic drivers.yml         # Provides an overview of a key concept (drivers.yml) utilized by the namespace
$ hodor master:topic clusters.yml       # Provides an overview of the clusters.yml file and its central role in Hodor
$ hodor master:topic secrets            # Overview of how to configure environment to manage and store sensitive information safely
```

Hodor Setup and Aliasing
===========================

This section demonstrates how one might use the hodor commands to during your Hadoop development effort. Before using `hodor`, you'll need to build and install the `hodor` gem locally:

```bash
gem build hodor.gemspec
gem install hodor-0.0.8.gem
```

To specify the Hadoop cluster a Hodor command should target, you have two options:

```bash
$ HADOOP_ENV=target_env hodor oozie:display_job /
```

Note, the name 'target_env' indicates which section in your config/clusters.yml file to use when defining your Hadoop cluster. Alternatively, you can avoid having to type the HADOOP_ENV prefix for every command, by adding the following to your `~/.bashrc':

```bash
export HADOOP_ENV=target_env  # name of target hadoop cluster defined in config/clusters.yml
```

You may also wish to consider adding a few aliases for the more frequently used Hodor commands. For example, the following
aliases can (optionally) be defined in your '~/.bashrc':

```bash
alias cj='hodor oozie:change_job'  # avoid trailing space with aliases. Can cause parse problems with zsh
alias dj='hodor oozie:display_job'  # avoid trailing space with aliases. Can cause parse problems with zsh
alias rj='hodor oozie:run_job'
```

Hodor Core Concepts & Assumptions:
==================================
Hodor's commands can be studied individually, but there are some larger principles that will shed light on
the assumptions those commands are making, and the concepts they are implementing. These topics are broken
down by Hodor Namespace as follows:

Master Topics
-------------
 * [The "clusters.yml" file](topics/master/clusters.yml.txt)

Oozie Topics
------------
 * [Inspecting Oozie Jobs](topics/oozie/inspecting_jobs.txt)
 * [Composing Job Properties](topics/oozie/composing_job_properties.txt)
 * [Workers And Drivers](topics/oozie/workers_and_drivers.txt)
 * [Driver Run Scenarios](topics/oozie/driver_scenarios.txt)
 * [Blocking Coordinators](topics/oozie/blocking_coordinators.txt)
 * [Deploying & Running Jobs](topics/oozie/jobs.yml.txt)

Hdfs Topics
-----------
 * [Corresponding Hdfs Paths](topics/hdfs/corresponding_paths.txt)

## Future / Enhancements

Pull requests will be very happily considered.

__Maintained by Dean Hallman__

## License

The MIT License (MIT)

Copyright (c) 2015 Dean Hallman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
