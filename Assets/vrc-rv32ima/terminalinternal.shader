﻿Shader "rv32ima/terminalinternal"
{
    Properties
    {
		_MainSystemMemory( "Main System Memory", 2D ) = "black" { }
		_ReadFromTerminal( "Read From Terminal", 2D ) = "black" { }
		[ToggleUI] _Clear( "Clear", float ) = 0
    }
    SubShader
    {
        Tags { }

		Pass
		{
			ZTest Always 

			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			Texture2D< uint4 > _ReadFromTerminal;
			Texture2D< uint4 > _MainSystemMemory;
			float4 _MainSystemMemory_TexelSize;
			float4 _ReadFromTerminal_TexelSize;
			float _Clear;
			
			struct appdata
			{
                float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex	: SV_POSITION;
				uint batchID	: TEXCOORD2;
			};
			
			v2f vert(appdata IN)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(IN.vertex);
				return o;
			}
			
			
			uint4 frag (v2f i) : SV_Target
            {
				uint2 charcoord = i.vertex.xy/i.vertex.w;

				const uint2 termsize = ( _ReadFromTerminal_TexelSize.zw - uint2( 0, 1 ) );
				uint rchar = _MainSystemMemory[uint2( 12, _MainSystemMemory_TexelSize.w - 1 )].y;
				uint2 cursor = uint2( _ReadFromTerminal[uint2(0,termsize.y)].x, _ReadFromTerminal[uint2(1,termsize.y)].x );
				int escapemode = _ReadFromTerminal[uint2(2,termsize.y)].x;
				uint4 ret = 0;

				bool bDidInit = false;
				bool bNeedToScroll = false;
				//if( rchar == 27 )
				{
				//	escapemode = 3;
				}

				if( escapemode > 0 )
				{
					escapemode--;
				}
				else
				{
					if( rchar >= 32 )
					{
						if( length( charcoord - cursor ) == 0 )
							ret.x = rchar;
						else
							ret.x = _ReadFromTerminal[charcoord].x;
							
						bDidInit = true;
						cursor.x++;
						if( cursor.x >= termsize.x )
						{
							cursor.x = 0;
							cursor.y++;
						}
					}

					if( rchar == 10 )
					{
						cursor.y++;
						cursor.x = 0;
					}
				}

				if( cursor.y >= termsize.y )
				{
					if( charcoord.y < termsize.y - 1 )
						ret.x = _ReadFromTerminal[charcoord + uint2( 0, 1 )].x;
					else
						ret.x = 0;
					cursor.y = termsize.y-1;
					// XXX TODO: If we went off the end of the line, handle that here.
				}
				else if( !bDidInit )
				{
					ret.x = _ReadFromTerminal[charcoord].x;
				}


				if( charcoord.y == termsize.y )
				{
					switch( charcoord.x )
					{
						case 0: ret.x = cursor.x; break;
						case 1: ret.x = cursor.y; break;
						default: break;
					}
				}
				
				if( _Clear > 0.5 ) ret = 0;
				
				return ret;
			}
			
			ENDCG
		}
    }
}
