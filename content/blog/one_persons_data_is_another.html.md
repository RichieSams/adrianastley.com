+++
banner: "/static/images/blog/one_persons_data_is_another/banner.jpg"
categories: ["ScummVM"]
date: 2013-07-29T11:51:00.002000-05:00
description: ""
images: []
tags: []
title: "One person's data is another person's noise"
template: "blog.html.jinja"
+++

I know it's been forever since I've done a post and I'm really sorry. I got caught up in the sound issues and panorama issues. I'm going to talk about sound in this post and then make another post about panoramas. So here we go!  

“One person's data is another person's noise.”  ― K.C. Cole  

This quote pretty much sums up my experiences with the sound decoding. I was somewhat lucky in that Marisa Chan's source code had an implementation of sound decoding that I could model off of, but at the same time, the whole function was quite cryptic. This is mostly due to the variable "naming". And I say "naming" in the loosest sense of the word, because most were single letters:  

```cpp
void adpcm8_decode(void *in, void *out, int8_t stereo, int32_t n)
{
    uint8_t *m1;
    uint16_t *m2;
    m1 = (uint8_t *)in;
    m2 = (uint16_t *)out;
    uint32_t a, x, j = 0;
    int32_t b, i, t[4] = {0, 0, 0, 0};

    while (n)
    {
        a = *m1;
        i = t[j+2];
        x = t2[i];
        b = 0;

        if(a & 0x40)
            b += x;
        if(a & 0x20)
            b += x >> 1;
        if(a & 0x10)
            b += x >> 2;
        if(a & 8)
            b += x >> 3;
        if(a & 4)
            b += x >> 4;
        if(a & 2)
            b += x >> 5;
        if(a & 1)
            b += x >> 6;

        if(a & 0x80)
            b = -b;

        b += t[j];

        if(b > 32767)
            b = 32767;
        else if(b < -32768)
            b = -32768;

        i += t1[(a >> 4) & 7];

        if(i < 0)
            i = 0;
        else if(i > 88)
            i = 88;

        t[j] = b;
        t[j+2] = i;
        j = (j + 1) & stereo;
        *m2 = b;

        m1++;
        m2++;
        n--;
    }
}
```
  
No offense intended towards Marisa Chan, but that makes my eyes hurt. It made understanding the algorithm that much harder. But after talking to a couple people at ScummVM and Wikipedia-ing general sound decoding, I figured out the sound is encoded using a modified Microsoft Adaptive PCM. I'll go ahead and post my implementation and then describe the process:

```cpp
const int16 RawZorkStream::_stepAdjustmentTable[8] = {-1, -1, -1, 1, 4, 7, 10, 12};

const int32 RawZorkStream::_amplitudeLookupTable[89] = {0x0007, 0x0008, 0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E,
                                                        0x0010, 0x0011, 0x0013, 0x0015, 0x0017, 0x0019, 0x001C, 0x001F,
                                                        0x0022, 0x0025, 0x0029, 0x002D, 0x0032, 0x0037, 0x003C, 0x0042,
                                                        0x0049, 0x0050, 0x0058, 0x0061, 0x006B, 0x0076, 0x0082, 0x008F,
                                                        0x009D, 0x00AD, 0x00BE, 0x00D1, 0x00E6, 0x00FD, 0x0117, 0x0133,
                                                        0x0151, 0x0173, 0x0198, 0x01C1, 0x01EE, 0x0220, 0x0256, 0x0292,
                                                        0x02D4, 0x031C, 0x036C, 0x03C3, 0x0424, 0x048E, 0x0502, 0x0583,
                                                        0x0610, 0x06AB, 0x0756, 0x0812, 0x08E0, 0x09C3, 0x0ABD, 0x0BD0,
                                                        0x0CFF, 0x0E4C, 0x0FBA, 0x114C, 0x1307, 0x14EE, 0x1706, 0x1954,
                                                        0x1BDC, 0x1EA5, 0x21B6, 0x2515, 0x28CA, 0x2CDF, 0x315B, 0x364B,
                                                        0x3BB9, 0x41B2, 0x4844, 0x4F7E, 0x5771, 0x602F, 0x69CE, 0x7462, 0x7FFF};

int RawZorkStream::readBuffer(int16 *buffer, const int numSamples) {
    uint32 bytesRead = 0;

    // 0: Left, 1: Right
    byte channel = 0;

    while (bytesRead < numSamples) {
        byte encodedSample = _stream->readByte();
        if (_stream->eos()) {
            _endOfData = true;
            return bytesRead;
        }
        bytesRead++;

        int16 index = _lastSample[channel].index;
        uint32 lookUpSample = _amplitudeLookupTable[index];

        int32 sample = 0;

        if (encodedSample & 0x40)
            sample += lookUpSample;
        if (encodedSample & 0x20)
            sample += lookUpSample >> 1;
        if (encodedSample & 0x10)
            sample += lookUpSample >> 2;
        if (encodedSample & 8)
            sample += lookUpSample >> 3;
        if (encodedSample & 4)
            sample += lookUpSample >> 4;
        if (encodedSample & 2)
            sample += lookUpSample >> 5;
        if (encodedSample & 1)
            sample += lookUpSample >> 6;
        if (encodedSample & 0x80)
            sample = -sample;

        sample += _lastSample[channel].sample;
        sample = CLIP(sample, -32768, 32767);

        buffer[bytesRead - 1] = (int16)sample;

        index += _stepAdjustmentTable[(encodedSample >> 4) & 7];
        index = CLIP<int16>(index, 0, 88);

        _lastSample[channel].sample = sample;
        _lastSample[channel].index = index;

        // Increment and wrap the channel
        channel = (channel + 1) & _stereo;
    }

    return bytesRead;
}
```

Each sample is encoded into 8 bits. The actual sound sample is read from the bits using a lookup table and an index from the previous 'frame'. This is then added to the sample from last 'frame'. Finally, the 4 high bits are used to set the index for the next 'frame'.

The biggest problem I ran into for sound was actually a typo on my part. The template argument for CLIP was accidentally set to a uint16 instead of a int16. This caused distortions at the extremely high and low ranges of the sound. But, this usually only occurred at the beginning and end of a sound clip. I spent days trying to figure out if I had set the initial lastSample correctly, or other random ideas. After pounding my head into the desk for 3 days, the glorious wjp came along and found my typo. After which, the sound worked perfectly. Shout out to wjp!!!!!!!!!

There is one other bug with sound and that's in videos. The sound has a slight 'ticking'. However, clone2727 identified it potentially as a problem with the AVI decoder. In the current state, the AVI decoder puts each sound 'chunk' into its own AudioStream, and then puts all the streams into a queue to be played. We're thinking the lastSample needs to persist from chunk to chunk. However, solving this problem would take either a gross hack, or a redesign of the AVI decoder. clone2727 has taken on the task, so I'm going to leave it to him and get back to the video audio later in the project.
  
Well, that's it for this post. Sound was pretty straightforward. I was only bogged down due to some really bad typos on my part. As always, feel free to comment or ask questions.

Happy coding! :)
