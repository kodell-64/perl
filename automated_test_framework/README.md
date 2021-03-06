Object-oriented Perl test framework.
Author: Korey O'Dell

### Design
Originally written circa 2007, expanded, maintained through 2016.

'ACME' company had many varied software technologies which necessitated an automated framework that could morph or adapt as needed.

Object-oriented Perl was chosen for a main driver app that instantiates test objects of the component under test.

Example: Issuing the command

'perl regression-test-v3.pl avcd'

starts the driver 'regression-test-v3.pl' which in and of itself created several internal objects for logging and input control.
Then, a 'avcd' object is instantiated from the 'TestClass' object and testing would commence.

This TestClass was the base class object for all tests and contained all parent and inheritable objects and functions for the testing framework.

Each module, 'avcd' for this example, contained all helper methods to provide the necessary inputs and the analysis methods to analyze the produced outputs of the software. Additional objects handled creating, updating test reports, sending notifications, etc.

The avcd module noted here requires a UDP-multicast TS (transport stream) as an input. avcd object methods spawned accessory applications to loop known input resources to loopback multicast address for the avcd software to ingest as input.
Perl's *IPC-Run CPAN module* (https://metacpan.org/pod/IPC::Run) is used heavily throughout the framework for subprocess handling, both on the input and output side of the software under test.

OOP and its inherent encapsulation and abstraction was chosen to guarantee adding, changing test modules would have zero chance of impacting other well-vetted test modules.

### Example of test object creation and inheritance

Let's use our avcd.pm module again.

Instantiation of the test framework creates a AVCD test object (avcdtests.pm) which inherits base-class functionality from our testclass.pm module. This happens with the object class's @ISA array.

```
our @ISA = qw( TestClass );
```

With that we have a AvcdTest object that is populated with data for each test that is to be executed. The test object contains test-specific inputs, parameters, and expected outputs.

### Adding a new module

With the code reuse and encapsulation provided with the OOP-design, adding a new software component to go under test was as easy as:
 * creating the component.pm and componenttest.pm modules
 * adding the tests with iterative steps to the component.pm module
 * informing the driver (regression-test-v3.pl) app of the new module
 
### Technologies used

The framework employs several CPAN Perl packages for I/O and other needs. We've mentioned IPC-Run, IO-Tee is another and is used for 'tee'ing together all STDOUT/STDERR output from the framework.

```
$tee = IO::Tee->new(\*STDOUT,">results/$packagename/$fullVersion/$fullVersion.log");
open(STDOUT, ">&$tee");
open(STDERR, ">&$tee");#/dev/null"); 
select $tee;
```

### History

The framework was heavily employed and used for every software release for almost ten years. It 
 * validated new features
 * regression tested for side-effect defects from code changes
 * provided performance/benchmark stats and metrics
 * even validated operating system 'image' changes
 * generated testing reports and documentation for audit needs.