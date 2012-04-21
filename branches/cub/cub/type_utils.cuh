/******************************************************************************
 * 
 * Copyright 2010-2012 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 * Thanks!
 * 
 ******************************************************************************/

/******************************************************************************
 * Common B40C Routines 
 ******************************************************************************/

#pragma once

namespace cub {


/******************************************************************************
 * Macro utilities
 ******************************************************************************/

/**
 * Select maximum
 */
#define B40C_MAX(a, b) ((a > b) ? a : b)


/**
 * Select maximum
 */
#define B40C_MIN(a, b) ((a < b) ? a : b)

/**
 * Return the size in quad-words of a number of bytes
 */
#define B40C_QUADS(bytes) (((bytes + sizeof(uint4) - 1) / sizeof(uint4)))

/******************************************************************************
 * Simple templated utilities
 ******************************************************************************/

/**
 * Supress warnings for unused constants
 */
template <typename T>
__host__ __device__ __forceinline__ void SuppressUnusedConstantWarning(const T) {}


/**
 * Perform a swap
 */
template <typename T> 
void __host__ __device__ __forceinline__ Swap(T &a, T &b) {
	T temp = a;
	a = b;
	b = temp;
}


/**
 * MagnitudeShift().  Allows you to shift left for positive magnitude values, 
 * right for negative.   
 */
template <int MAGNITUDE, int shift_left = (MAGNITUDE >= 0)>
struct MagnitudeShift
{
	template <typename K>
	__device__ __forceinline__ static K Shift(K key)
	{
		return key << MAGNITUDE;
	}
};


template <int MAGNITUDE>
struct MagnitudeShift<MAGNITUDE, 0>
{
	template <typename K>
	__device__ __forceinline__ static K Shift(K key)
	{
		return key >> (MAGNITUDE * -1);
	}
};


/******************************************************************************
 * Metaprogramming Utilities
 ******************************************************************************/

/**
 * Null type
 */
struct NullType {};


/**
 * Statically determine log2(N), rounded up, e.g.,
 * 		Log2<8>::VALUE == 3
 * 		Log2<3>::VALUE == 2
 */
template <int N, int CURRENT_VAL = N, int COUNT = 0>
struct Log2
{
	// Inductive case
	static const int VALUE = Log2<N, (CURRENT_VAL >> 1), COUNT + 1>::VALUE;
};

template <int N, int COUNT>
struct Log2<N, 0, COUNT>
{
	// Base case
	static const int VALUE = (1 << (COUNT - 1) < N) ?
		COUNT :
		COUNT - 1;
};


/**
 * If/Then/Else
 */
template <bool IF, typename ThenType, typename ElseType>
struct If
{
	// true
	typedef ThenType Type;
};

template <typename ThenType, typename ElseType>
struct If<false, ThenType, ElseType>
{
	// false
	typedef ElseType Type;
};


/**
 * Equals 
 */
template <typename A, typename B>
struct Equals
{
	enum {
		VALUE = 0,
		NEGATE = 1
	};
};

template <typename A>
struct Equals <A, A>
{
	enum {
		VALUE = 1,
		NEGATE = 0
	};
};



/**
 * Is volatile
 */
template <typename Tp>
struct IsVolatile
{
	enum { VALUE = 0 };
};
template <typename Tp>
struct IsVolatile<Tp volatile>
{
	enum { VALUE = 1 };
};


/**
 * Removes pointers
 */
template <typename Tp, typename Up = Tp>
struct RemovePointers
{
	typedef Tp Type;
};
template <typename Tp, typename Up>
struct RemovePointers<Tp, Up*>
{
	typedef typename RemovePointers<Up, Up>::Type Type;
};


/**
 * Removes qualifiers
 */
template <typename Tp, typename Up = Tp>
struct RemoveQualifiers
{
	typedef Up Type;
};

template <typename Tp, typename Up>
struct RemoveQualifiers<Tp, volatile Up>
{
	typedef Up Type;
};

template <typename Tp, typename Up>
struct RemoveQualifiers<Tp, const Up>
{
	typedef Up Type;
};

template <typename Tp, typename Up>
struct RemoveQualifiers<Tp, const volatile Up>
{
	typedef Up Type;
};


/**
 * Utility for finding dimensions and base types of opaque array typenames.
 * Usage for an array type ArrayType1:
 *
 *     ArrayProps<ArrayType1>::DIMS;									// Number of dimensions
 * 	   ArrayProps<ArrayType1>::LENGTH									// Length of first dimension
 *	   ArrayProps<typename ArrayProps<ArrayType1>::Element>::LENGTH		// Length of second dimension (possibly zero)
 */

// Function declarations for finding length of array
template <typename T, int X>
static char (&ArrayLength(T (*array)[X]))[X + 1];		// Return value is size (in bytes) of the input array

template <typename T>
static char (&ArrayLength(T*))[1];						// Parameter is not of type pointer-to-array

template <
	typename Array,
	typename Element = Array,
	int LENGTH = sizeof(ArrayLength((Array *) NULL)) - 1>
struct ArrayProps;

// Specialization for base type (non array type)
template <typename Array, typename _Element, int _LENGTH>
struct ArrayProps
{
	typedef _Element Element;						// Element type
	typedef Array BaseElement;						// BaseElement element

	enum {
		LENGTH 			= _LENGTH,
		DIMS			= 0
	};
};

// Specialization for array type
template <typename Array, typename _Element, int _LENGTH>
struct ArrayProps<Array, _Element[_LENGTH], _LENGTH>
{
	typedef _Element Element;						// Element type
	typedef typename ArrayProps<_Element>::BaseElement BaseElement;		// BaseElement element type

	enum {
		LENGTH 			= _LENGTH,
		DIMS			= ArrayProps<Element>::DIMS + 1
	};
};



} // namespace cub

