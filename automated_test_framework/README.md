Object-oriented Perl test framework.

### Design
Originally written circa 2007, expanded, maintained through 2016.

'ACME' company had many varied software technologies which necessitated an automated framework that could morph or adapt as needed.

Object-oriented Perl was chosen for a main driver app that instantiates test objects of the component under test.

Example: Issuing the command

'perl regression-test-v3.pl avcd'

starts the driver 'regression-test-v3.pl' which in and of itself created several internal objects for logging and input control.
Then, a 'avcd' object is instantiated from the 'TestClass' object and testing would commence.

This TestClass was the base class object for all tests and contained all parent and inheritable objects and functions for the testing framework.

Each module 'avcd' for example contained all helper methods to provide the necessary inputs and the analysis methods to analyze the produced outputs of the software. Additional objects handled creating, updating test reports, sending notifications, etc.

The avcd module noted here actually required a UDP-multicast TS (transport stream) as an input. Methods spawned accessory applications to loop known input resources to loopback multicase added for the avcd software to ingest as input. Perl's *IPC-Run CPAN module* (https://metacpan.org/pod/IPC::Run) is used heavily throughout the framework for subprocess handling.