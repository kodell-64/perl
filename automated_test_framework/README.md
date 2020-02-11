Object-oriented Perl test framework.

### Design
Originally written circa 2007, expanded, maintained through 2016.

'ACME' company had many varied software technologies which necessitated an automated framework that could morph or adapt as needed.

I chose to use object-oriented Perl where I created a main driver app that instantiated test objects of the component under test.
Example: Issuing the command
'perl regression-test-v3.pl avcd'

would start the driver which in and of itself created several objects for logging and input control.
Then, a 'TestClass' object would be instantiated from the 'avcd' object and testing would commence.
The TestClass was the base class object for all tests and contained all parent and inheritable objects and functions for the test framework.

Some components needed UDP-multicast datagram streams flowing as input