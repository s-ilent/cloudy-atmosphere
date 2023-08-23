/*
Stars and galaxy 
Created by mrange in 2022-04-10

License CC0: Stars and galaxy
Bit of sunday tinkering lead to stars and a galaxy
Didn't turn out as I envisioned but it turned out to something
that I liked so sharing it.
*/

#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))

float tanh_approx(float x)
{
    float x2 = x*x;
    return clamp(x*(27.+x2)/(27.+9.*x2), -1., 1.);
}

static const float4 hsv2rgb_K = float4(1., 2./3., 1./3., 3.);
float3 hsv2rgb(float3 c)
{
    float3 p = abs(frac(c.xxx+hsv2rgb_K.xyz)*6.-hsv2rgb_K.www);
    return c.z*lerp(hsv2rgb_K.xxx, clamp(p-hsv2rgb_K.xxx, 0., 1.), c.y);
}

float2 mod2(inout float2 p, float2 size)
{
    float2 c = floor((p+size*0.5)/size);
    p = glsl_mod(p+size*0.5, size)-size*0.5;
    return c;
}
float2 hash2(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return frac(sin(p)*43758.547);
}
float2 shash2(float2 p)
{
    return -1.+2.*hash2(p);
}
float3 toSpherical(float3 p)
{
    float r = length(p);
    float t = acos(p.z/r);
    float ph = atan2(p.y, p.x);
    return float3(r, t, ph);
}
float3 blackbody(float Temp)
{
    float3 col = ((float3)255.);
    col.x = 56100000.*pow(Temp, -3./2.)+148.;
    col.y = 100.04*log(Temp)-623.6;
    if (Temp>6500.)
        col.y = 35200000.*pow(Temp, -3./2.)+184.;
        
    col.z = 194.18*log(Temp)-1448.6;
    col = clamp(col, 0., 255.)/255.;
    if (Temp<1000.)
        col *= Temp/1000.;
        
    return col;
}

float3 stars(float3 ro, float3 rd, float2 sp, float hh)
{
    float3 col = ((float3)0.);
    const float m = 5.0; // stars layers
    hh = tanh_approx(20.*hh);
    for (float i = 0.;i<m; ++i)
    {
        float2 pp = sp+0.5*i;
        float s = i/(m-1.);
        float2 dim = ((float2)lerp(0.05, 0.003, s)*PI);
        float2 np = mod2(pp, dim);
        float2 h = hash2(np+127.+i);
        float2 o = -1.+2.*h;
        float y = sin(sp.x);
        pp += o*dim*0.5;
        pp.y *= y;
        float l = length(pp);
        float h1 = frac(h.x*1667.);
        float h2 = frac(h.x*1887.);
        float h3 = frac(h.x*2997.);
        float3 scol = lerp(8.*h2, 0.25*h2*h2, s)*blackbody(lerp(3000., 22000., h1*h1));
        float3 ccol = col+exp(-(lerp(6000., 2000., hh)/lerp(2., 0.25, s))*max(l-0.001, 0.))*scol;
        col = h3<y ? ccol : col;
    }
    return col;
}

float3 sky(float3 ro, float3 rd, float2 sp, float3 lp, out float cf)
{
    cf = 0;
    float ld = max(dot(normalize(lp-ro), rd), 0.);
    float y = -0.5+sp.x/PI;
    y = max(abs(y)-0.02, 0.)+0.1*smoothstep(0.5, PI, abs(sp.y));
    float3 blue = hsv2rgb(float3(0.6, 0.75, 0.35*exp(-15.*y)));
    float ci = pow(ld, 10.)*2.*exp(-25.*y);
    float3 yellow = blackbody(1500.)*ci;
    cf = ci;
    return blue+yellow;
}

float2 raySphere(float3 ro, float3 rd, float4 sph)
{
    float3 oc = ro-sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc)-sph.w*sph.w;
    float h = b*b-c;
    if (h<0.)
        return ((float2)-1.);
        
    h = sqrt(h);
    return float2(-b-h, -b+h);
}

float4 moon(float3 ro, float3 rd, float2 sp, float3 lp, float4 md)
{
    float2 mi = raySphere(ro, rd, md);
    float3 p = ro+mi.x*rd;
    float3 n = normalize(p-md.xyz);
    float3 r = reflect(rd, n);
    float3 ld = normalize(lp-p);
    float fre = dot(n, rd)+1.;
    fre = pow(fre, 15.);
    float dif = max(dot(ld, n), 0.);
    float spe = pow(max(dot(ld, r), 0.), 8.);
    float i = 0.5*tanh_approx(20.*fre*spe+0.05*dif);
    float3 col = blackbody(1500.)*i+hsv2rgb(float3(0.6, lerp(0.6, 0., i), i));
    float t = tanh_approx(0.25*(mi.y-mi.x));
    return float4(((float3)col), t);
}

float3 getNightSky(float3 ro, float3 rd)
{
    float2 sp = toSpherical(rd.xzy).yz;
    float sf = 0.;
    float cf = 0.;

	return stars(ro, rd, sp, sf)*(1.-tanh_approx(2.*cf));
}

float3 getNightHaze(float3 ro, float3 rd, float3 lp_in)
{
    float2 sp = toSpherical(rd.xzy).yz;
    float sf = 0.;
    float cf = 0.;
	//float3 lp = float3(1., -0.25, 0.) + 500.0;
    float3 lp = lp_in + 500.0;

	return sky(ro, rd, sp, lp, cf);
}

float4 getMoon(float3 ro, float3 rd)
{
    float2 sp = toSpherical(rd.xzy).yz;
	float3 lp = 500.*float3(1., -0.25, 0.);
	float4 md = 50.*float4(float3(1., 1., -0.6), 0.5);

	return moon(ro, rd, sp, lp, md);
}

#undef glsl_mod