Perl-based PCM-audio analyzer to detect known audio clips.
Author: Korey O'Dell

### Design

Uses:
 * Fast-fourier mathematic transform to spectral energy from mono, PCM s16le audio samples.
 * energy 'fingerprints' are hashed to database table and each 125ms sample is represented by 8, 64 bit integers (512 bits).
 * closed-captioning information is also extracted, datastored

 

### Notes:
 * heavy POC (proof of concept) code so it is messy.
 
### History

 * I also wrote a version of this in pthreaded C to harness multiple CPU cores.