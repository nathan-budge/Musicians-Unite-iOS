////////////////////////////////////////////////////////////////////////////////
///
/// \file types.hpp
/// ---------------
///
/// Copyright (c) 2012 - 2015. Little Endian Ltd. All rights reserved.
///
////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------
#ifndef types_hpp__2E2AF898_66C0_44F5_B438_B923A399AB35
#define types_hpp__2E2AF898_66C0_44F5_B438_B923A399AB35
#pragma once
//------------------------------------------------------------------------------
#include "le/utility/abi.hpp"
//------------------------------------------------------------------------------
namespace LE
{
//------------------------------------------------------------------------------
namespace Meter
{
//------------------------------------------------------------------------------

typedef float real_t;

template <typename T> struct InterleavedData { typedef T * LE_RESTRICT                     type; };
template <typename T> struct SeparatedData   { typedef T * LE_RESTRICT const * LE_RESTRICT type; };

typedef InterleavedData<real_t const>::type InterleavedInputChannels; ///< A typedef for float const *
typedef SeparatedData  <real_t const>::type SeparatedInputChannels  ; ///< A typedef for float const * const *

typedef InterleavedData<real_t      >::type InterleavedOutputChannels; ///< A typedef for float *
typedef SeparatedData  <real_t      >::type SeparatedOutputChannels  ; ///< A typedef for float const * *

//------------------------------------------------------------------------------
} // namespace Meter
//------------------------------------------------------------------------------
} // namespace LE
//------------------------------------------------------------------------------
#endif // types_hpp
