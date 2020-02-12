Perl-based PCM-audio analyzer to detect known audio clips from 2-hour long a/v recordings.
Author: Korey O'Dell

### Design

Uses:
 * Fast-fourier transform used to 'discretize' frequency and time values of mono, PCM s16le (original) audio samples.
 * energy 'fingerprints' are hashed to database table and each 125ms sample is represented by 8, 64 bit integers (512 bits).
 * closed-captioning information is also extracted, datastored
 * uses Inline-C module for embedding C in critical sections for performance
 * mysql database functions for datastore
 
### Notes:
 * heavy POC (proof of concept) code so it is messy. 
 
### History
 * I also wrote a version of this in pthreaded C to harness multiple CPU cores.