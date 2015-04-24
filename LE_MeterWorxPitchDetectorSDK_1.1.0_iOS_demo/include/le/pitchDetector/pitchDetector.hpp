////////////////////////////////////////////////////////////////////////////////
///
/// \file pitchDetector.hpp
/// -----------------------
///
/// Copyright (c) 2013 - 2015. Little Endian Ltd. All rights reserved.
///
////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------
#ifndef pitchDetector_hpp__919338C5_0497_4FB1_99AA_0EFC6D0DBE9E
#define pitchDetector_hpp__919338C5_0497_4FB1_99AA_0EFC6D0DBE9E
#pragma once
//------------------------------------------------------------------------------
#include "types.hpp"

#include "le/utility/abi.hpp"
#include "le/utility/pimpl.hpp"

#include <utility>
//------------------------------------------------------------------------------
#if defined( _MSC_VER ) && !defined( LE_SDK_NO_AUTO_LINK )
    #ifdef _WIN64
        #pragma comment( lib, "MeterWorxPitchDetectorSDK_Win64_x86-64_SSE3.lib" )
    #else // _WIN32
        #pragma comment( lib, "MeterWorxPitchDetectorSDK_Win32_x86-32_SSE2.lib" )
    #endif // _WIN32/64
#endif // _MSC_VER && !LE_SDK_NO_AUTO_LINK
//------------------------------------------------------------------------------
namespace LE
{
//------------------------------------------------------------------------------
namespace Meter /// \brief Root namespace for all PitchDetector SDK components
{
//------------------------------------------------------------------------------

/// \addtogroup Meter
/// \brief LE MeterWorx components
/// @{

////////////////////////////////////////////////////////////////////////////////
///
/// \class PitchDetector
///
/// \brief Pitch detector. Finds pitch for each input channel and provides the 
/// "winner" pitch. 
///
/// \nosubgrouping
///
////////////////////////////////////////////////////////////////////////////////

class PitchDetector
#ifndef DOXYGEN_ONLY
    :
    public Utility::StackPImpl<PitchDetector, 21 * sizeof( void * ) + 36 * sizeof( int ), 16>
#endif // DOXYGEN_ONLY
{
public:
    /// \name Setup:
    /// @{

    LE_NOTHROWNOALIAS  PitchDetector();
    LE_NOTHROWNOALIAS ~PitchDetector();

    ////////////////////////////////////////////////////////////////////////////
    //
    // PitchDetector::setPitchRange()
    // ------------------------------
    //
    ////////////////////////////////////////////////////////////////////////////
    ///
    /// \brief Defines the target frequency range in which to search for the pitch.
    /// Defaults to the [55 Hz, 14080 Hz] range which is an 8 octave range 
    /// starting with the tone A0. A different range can be set according to the
    /// type of input audio signal.
    ///
    ////////////////////////////////////////////////////////////////////////////

    LE_NOTHROWNOALIAS void LE_FASTCALL_ABI setPitchRange( unsigned int lowerFrequencyBound, unsigned int upperFrequencyBound );


    ////////////////////////////////////////////////////////////////////////////
    //
    // PitchDetector::setup()
    // ----------------------
    //
    ////////////////////////////////////////////////////////////////////////////
    ///
    /// \brief Prepares the pitch detector instance for processing.
    ///
    /// \param sampleRate       All subsequent process*() calls (until the next
    ///                         call to setup()) will assume this sampling rate.
    /// \param numberOfChannels All subsequent process*() calls (until the next
    ///                         call to setup()) will assume this many channels.
    ///
    /// \return                 True if successful, false if unable to allocate
    ///                         enough memory.
    ///
    ////////////////////////////////////////////////////////////////////////////

    LE_NOTHROWNOALIAS bool LE_FASTCALL_ABI setup( unsigned int sampleRate, unsigned int numberOfChannels );

    /// @}

public:
    /// \name Processing:
    /// @{

    ////////////////////////////////////////////////////////////////////////////
    //
    // PitchDetector::process()
    // ------------------------
    //
    ////////////////////////////////////////////////////////////////////////////
    ///
    /// \brief Main process function for separated (non-interleaved) input data.
    ///
    /// \param pData           Pointer to an array of pointers to separated
    ///                        input channels (which must provide data for at
    ///                        least the number of channels as was specified by
    ///                        the numberOfChannels parameter in the last call
    ///                        to setup()).
    /// \param numberOfSamples Number of samples to process from pData (there is
    ///                        no limit on the number of samples that can be
    ///                        processed in one call).
    ///
    ////////////////////////////////////////////////////////////////////////////

    LE_NOTHROWNOALIAS void LE_FASTCALL_ABI process( SeparatedInputChannels   pData, unsigned int numberOfSamples ) const;

    /// \brief Main process function for interleaved input data.
    /// \overload
    /// \note This overload has additional overhead compared to the separated
    /// channels version so it is more efficient to use the separated version if
    /// possible.
    LE_NOTHROWNOALIAS void LE_FASTCALL_ABI process( InterleavedInputChannels pData, unsigned int numberOfSamples ) const;

    LE_NOTHROWNOALIAS void LE_FASTCALL_ABI reset(); ///< Resets the pitch detector instance (e.g. before processing a new stream of data).

    /// @}

public:
    /// \name Result access:
    /// \brief Values obtained after the last call to process():
    /// @{

    /// \brief Detected pitch data
    struct Pitch
    {
        float        frequency ; ///< Detected pitch in Hz.
        float        amplitude ; ///< Amplitude of the frequency detected as pitch in dB.
        unsigned int confidence; ///< A heuristic measurement of the quality of pitch detection in the range from 0 to 5 (with 0 corresponding to no valid detected pitch).
    }; // struct Pitch

    /// \brief Detected pitch for the given channel.
    LE_NOTHROWNOALIAS Pitch const & LE_FASTCALL_ABI pitch( unsigned int channel ) const;

    /// \brief The resultant, heuristically determined "winner" pitch of a
    /// multi-channel signal.
    LE_NOTHROWNOALIAS Pitch const & LE_FASTCALL_ABI pitch(                      ) const;

    /// @}
}; // class PitchDetector

/// @} // group Meter

//------------------------------------------------------------------------------
} // namespace Meter
//------------------------------------------------------------------------------
} // namespace LE
//------------------------------------------------------------------------------
#endif // pitchDetector_hpp
