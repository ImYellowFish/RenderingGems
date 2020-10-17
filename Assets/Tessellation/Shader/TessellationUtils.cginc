#ifndef TESSELLATION_UTILS_INCLUDED
#define TESSELLATION_UTILS_INCLUDED

[maxvertexcount(3)]
void WireframeGeometryProgram(triangle InterpolatorsVertex i[3], inout TriangleStream<InterpolatorsGeometry> stream)
{
	float3 normal = normalize(cross(i[0].worldPos - i[1].worldPos, i[0].worldPos - i[2].worldPos));
	i[0].worldNormal = normal;
	i[1].worldNormal = normal;
	i[2].worldNormal = normal;

	InterpolatorsGeometry g0, g1, g2;
	g0.data = i[0];
	g1.data = i[1];
	g2.data = i[2];
	
	g0.barycentricCoordinates = float3(1, 0, 0);
	g1.barycentricCoordinates = float3(0, 1, 0);
	g2.barycentricCoordinates = float3(0, 0, 1);
	
	stream.Append(g0);
	stream.Append(g1);
	stream.Append(g2);
}


struct TessellationFactors
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};


[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("TestPatchConstantFunction")]
TessellationControlVertexData TestConstantHullProgram(InputPatch<TessellationControlVertexData, 3> patch, uint id: SV_OutputControlPointID)
{
	return patch[id];
}


[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("TestPatchClipSpaceTessFunction")]
TessellationControlVertexData TestHullProgram(InputPatch<TessellationControlVertexData, 3> patch, uint id: SV_OutputControlPointID)
{
	return patch[id];
}

float _TessellationUniform;
float _TessellationEdgeWidth;
float TestPatchGetTessFactor(TessellationControlVertexData p1, TessellationControlVertexData p2)
{
	float4 c1 = UnityObjectToClipPos(p1.vertex);
	float4 c2 = UnityObjectToClipPos(p2.vertex);
	float screenSpaceEdgeLength = distance(c1.xy / c1.w, c2.xy / c2.w);
	return screenSpaceEdgeLength * _ScreenParams.y / _TessellationEdgeWidth;
}


TessellationFactors TestPatchConstantFunction(InputPatch<TessellationControlVertexData, 3> patch)
{
	TessellationFactors f;
	f.edge[0] = 2.0;
	f.edge[1] = 2.0;
	f.edge[2] = 2.0;
	f.inside = 2.0;
	return f;
}


TessellationFactors TestPatchClipSpaceTessFunction(InputPatch<TessellationControlVertexData, 3> patch)
{
	TessellationFactors f;
	f.edge[0] = TestPatchGetTessFactor(patch[1], patch[2]);
	f.edge[1] = TestPatchGetTessFactor(patch[2], patch[0]);
	f.edge[2] = TestPatchGetTessFactor(patch[0], patch[1]);
	f.inside = (TestPatchGetTessFactor(patch[1], patch[2]) + TestPatchGetTessFactor(patch[2], patch[0]) + TestPatchGetTessFactor(patch[0], patch[1])) / 3.0;
	return f;
}

#define DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, fieldName) data.fieldName = \
	patch[0].fieldName * barycentricCoordinates.x + \
	patch[1].fieldName * barycentricCoordinates.y + \
	patch[2].fieldName * barycentricCoordinates.z

#ifdef ENABLE_TESSELLATION_DISPLACEMENT
sampler2D _TessDisplacementMap;
float4 _TessDisplacementMap_ST;
float _TessDisplacementStrength;
#endif

InterpolatorsVertex TestDomainProcessVertex(TessellationControlVertexData v)
{
	InterpolatorsVertex o;
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	
	#ifdef ENABLE_TESSELLATION_DISPLACEMENT
		float2 displacementUV = TRANSFORM_TEX(v.uv, _TessDisplacementMap);
		float displacement = tex2Dlod(_TessDisplacementMap, float4(displacementUV, 0, 0)).g;
		o.worldPos.xyz = o.worldPos.xyz + o.worldNormal * (displacement - 0.5) * _TessDisplacementStrength;
	#endif
	
	o.vertex = UnityWorldToClipPos(o.worldPos.xyz);

	o.shadowCoord = mul(unity_WorldToShadow[0], o.worldPos);

	return o;
}

[UNITY_domain("tri")]
InterpolatorsVertex TestDomainProgram(TessellationFactors factors,
	OutputPatch<TessellationControlVertexData, 3> patch,
	float3 barycentricCoordinates : SV_DomainLocation)
{
	TessellationControlVertexData data;
	DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, vertex);
	DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, normal);
	DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, uv);

	return TestDomainProcessVertex(data);
}


// For shadows
InterpolatorsVertex TestDomainProcessVertexShadow(TessellationControlVertexData v)
{
	InterpolatorsVertex o;
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.shadowCoord = float4(1, 1, 1, 1);

#ifdef ENABLE_TESSELLATION_DISPLACEMENT
	float2 displacementUV = TRANSFORM_TEX(v.uv, _TessDisplacementMap);
	float displacement = tex2Dlod(_TessDisplacementMap, float4(displacementUV, 0, 0)).g;
	o.worldPos.xyz = o.worldPos.xyz + o.worldNormal * (displacement - 0.5) * _TessDisplacementStrength;
#endif
	
	float3 wPos = o.worldPos;
	if (unity_LightShadowBias.z != 0.0)
	{
		float3 wNormal = UnityObjectToWorldNormal(v.normal);
		float3 wLight = normalize(UnityWorldSpaceLightDir(wPos.xyz));

		// apply normal offset bias (inset position along the normal)
		// bias needs to be scaled by sine between normal and light direction
		// (http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/)
		//
		// unity_LightShadowBias.z contains user-specified normal offset amount
		// scaled by world space texel size.

		float shadowCos = dot(wNormal, wLight);
		float shadowSine = sqrt(1 - shadowCos * shadowCos);
		float normalBias = unity_LightShadowBias.z * shadowSine;

		wPos.xyz -= wNormal * normalBias;
	}
	
	o.vertex = mul(UNITY_MATRIX_VP, float4(wPos, 1.0));
	o.vertex = UnityApplyLinearShadowBias(o.vertex);

	return o;
}

[UNITY_domain("tri")]
InterpolatorsVertex TestDomainProgramShadow(TessellationFactors factors,
	OutputPatch<TessellationControlVertexData, 3> patch,
	float3 barycentricCoordinates : SV_DomainLocation)
{
	TessellationControlVertexData data;
	DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, vertex);
	DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, normal);
	DOMAIN_INTERPOLATE(data, patch, barycentricCoordinates, uv);

	return TestDomainProcessVertexShadow(data);
}


#endif