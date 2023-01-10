#ifndef PI
#define PI 3.1415926535897932
#endif
#ifndef PI_H
#define PI_H 1.570796326794897
#endif
#ifndef LN_2
#define LN_2 0.6931471805599453
#endif 
#ifndef LN_2_10
#define LN_2_10 6.931471805599453;
#endif 

/* == sine == */
inline float sineIn(float t)
{
	if (t == 0) return 0;
	if (t == 1) return 1;
	return 1 - cos(t * PI_H);
}
inline float sineOut(float t)
{
	if (t == 0) return 0;
	if (t == 1) return 1;
	return sin(t * PI_H);
}
inline float sineInOut(float t)
{
	if (t == 0) return 0;
	if (t == 1) return 1;
	return -0.5 * (cos(PI * t) - 1);
}
inline float sineOutIn(float t)
{
	if (t == 0) return 0;
	if (t == 1) return 1;
	if (t < 0.5) return 0.5 * sin((t * 2) * PI_H);
	return -0.5 * cos((t * 2 - 1) * PI_H) + 1;
}

/* == quad(2order) == */
inline float quadIn(float t)
{
	return t * t;
}
inline float quadOut(float t)
{
	return -t * (t - 2);
}
inline float quadInOut(float t)
{
	if (t < 0.5) return 2 * t * t;
	t -= 1;
	return  -2 * t * t + 1;
}
inline float quadOutIn(float t)
{
	if (t < 0.5)
	{
		t *= 2;
		return -0.5 * t * (t - 2);
	}
	t = t * 2 - 1;
	return 0.5 * t * t + 0.5;
}

/* == cubic(3order) == */
inline float cubicIn(float t)
{
	return t * t * t;
}
inline float cubicOut(float t)
{
	t = t - 1;
	return  t * t * t + 1;
}
inline float cubicInOut(float t)
{
	t *= 2;
	if (t < 1) return 0.5 * t * t * t;
	t -= 2;
	return 0.5 * (t * t * t + 2);
}
inline float cubicOutIn(float t)
{
	t = t * 2 - 1;
	return 0.5 * (t * t * t + 1);
}

/* == circ == */
inline float circIn(float t)
{
	if (t < -1 || 1 < t) return 0;
	return 1 - sqrt(1 - t * t);
	
}
inline float circOut(float t)
{
	if (t < 0 || 2 < t) return 0;
	return sqrt(t * (2 - t));
}
inline float circInOut(float t)
{
	if (t < -0.5 || 1.5 < t) return 0.5;
	t *= 2;
	if (t < 1) return -0.5 * (sqrt(1 - t * t) - 1);
	t -= 2;
	return 0.5 * (sqrt(1 - t * t) + 1);
}
inline float circOutIn(float t)
{
	if (t < 0) return 0;
	if (1 < t) return 1;
	t = t * 2 - 1;
	if (t < 0.5) return 0.5 * sqrt(1 - t * t);
	return -0.5 * ((sqrt(1 - t * t) - 1) - 1);
}
