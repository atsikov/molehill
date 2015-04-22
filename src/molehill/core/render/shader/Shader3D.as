package molehill.core.render.shader
{
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;

	public class Shader3D
	{
		protected static const OC:ShaderRegister = new ShaderRegister("oc");
		protected static const OP:ShaderRegister = new ShaderRegister("op");
		
		protected static const V0:ShaderRegister = new ShaderRegister("v0");
		protected static const V1:ShaderRegister = new ShaderRegister("v1");
		protected static const V2:ShaderRegister = new ShaderRegister("v2");
		protected static const V3:ShaderRegister = new ShaderRegister("v3");
		protected static const V4:ShaderRegister = new ShaderRegister("v4");
		protected static const V5:ShaderRegister = new ShaderRegister("v5");
		protected static const V6:ShaderRegister = new ShaderRegister("v6");
		protected static const V7:ShaderRegister = new ShaderRegister("v7");
		
		protected static const VA0:ShaderRegister = new ShaderRegister("va0");
		protected static const VA1:ShaderRegister = new ShaderRegister("va1");
		protected static const VA2:ShaderRegister = new ShaderRegister("va2");
		protected static const VA3:ShaderRegister = new ShaderRegister("va3");
		protected static const VA4:ShaderRegister = new ShaderRegister("va4");
		protected static const VA5:ShaderRegister = new ShaderRegister("va5");
		protected static const VA6:ShaderRegister = new ShaderRegister("va6");
		protected static const VA7:ShaderRegister = new ShaderRegister("va7");
		
		protected static const VT0:ShaderRegister = new ShaderRegister("vt0");
		protected static const VT1:ShaderRegister = new ShaderRegister("vt1");
		protected static const VT2:ShaderRegister = new ShaderRegister("vt2");
		protected static const VT3:ShaderRegister = new ShaderRegister("vt3");
		protected static const VT4:ShaderRegister = new ShaderRegister("vt4");
		protected static const VT5:ShaderRegister = new ShaderRegister("vt5");
		protected static const VT6:ShaderRegister = new ShaderRegister("vt6");
		protected static const VT7:ShaderRegister = new ShaderRegister("vt7");
		
		protected static const FT0:ShaderRegister = new ShaderRegister("ft0");
		protected static const FT1:ShaderRegister = new ShaderRegister("ft1");
		protected static const FT2:ShaderRegister = new ShaderRegister("ft2");
		protected static const FT3:ShaderRegister = new ShaderRegister("ft3");
		protected static const FT4:ShaderRegister = new ShaderRegister("ft4");
		protected static const FT5:ShaderRegister = new ShaderRegister("ft5");
		protected static const FT6:ShaderRegister = new ShaderRegister("ft6");
		protected static const FT7:ShaderRegister = new ShaderRegister("ft7");
		
		protected static const VC0:ShaderRegister = new ShaderRegister("vc0");
		protected static const VC1:ShaderRegister = new ShaderRegister("vc1");
		protected static const VC2:ShaderRegister = new ShaderRegister("vc2");
		protected static const VC3:ShaderRegister = new ShaderRegister("vc3");
		protected static const VC4:ShaderRegister = new ShaderRegister("vc4");
		protected static const VC5:ShaderRegister = new ShaderRegister("vc5");
		protected static const VC6:ShaderRegister = new ShaderRegister("vc6");
		protected static const VC7:ShaderRegister = new ShaderRegister("vc7");
		protected static const VC8:ShaderRegister = new ShaderRegister("vc8");
		protected static const VC9:ShaderRegister = new ShaderRegister("vc9");
		protected static const VC10:ShaderRegister = new ShaderRegister("vc10");
		protected static const VC11:ShaderRegister = new ShaderRegister("vc11");
		protected static const VC12:ShaderRegister = new ShaderRegister("vc12");
		protected static const VC13:ShaderRegister = new ShaderRegister("vc13");
		protected static const VC14:ShaderRegister = new ShaderRegister("vc14");
		protected static const VC15:ShaderRegister = new ShaderRegister("vc15");
		
		protected static const FC0:ShaderRegister = new ShaderRegister("fc0");
		protected static const FC1:ShaderRegister = new ShaderRegister("fc1");
		protected static const FC2:ShaderRegister = new ShaderRegister("fc2");
		protected static const FC3:ShaderRegister = new ShaderRegister("fc3");
		protected static const FC4:ShaderRegister = new ShaderRegister("fc4");
		protected static const FC5:ShaderRegister = new ShaderRegister("fc5");
		protected static const FC6:ShaderRegister = new ShaderRegister("fc6");
		protected static const FC7:ShaderRegister = new ShaderRegister("fc7");
		protected static const FC8:ShaderRegister = new ShaderRegister("fc8");
		protected static const FC9:ShaderRegister = new ShaderRegister("fc9");
		protected static const FC10:ShaderRegister = new ShaderRegister("fc10");
		protected static const FC11:ShaderRegister = new ShaderRegister("fc11");
		protected static const FC12:ShaderRegister = new ShaderRegister("fc12");
		protected static const FC13:ShaderRegister = new ShaderRegister("fc13");
		protected static const FC14:ShaderRegister = new ShaderRegister("fc14");
		protected static const FC15:ShaderRegister = new ShaderRegister("fc15");
		
		protected static const FS0:ShaderRegister = new ShaderRegister("fs0");
		protected static const FS1:ShaderRegister = new ShaderRegister("fs1");
		protected static const FS2:ShaderRegister = new ShaderRegister("fs2");
		protected static const FS3:ShaderRegister = new ShaderRegister("fs3");
		protected static const FS4:ShaderRegister = new ShaderRegister("fs4");
		protected static const FS5:ShaderRegister = new ShaderRegister("fs5");
		protected static const FS6:ShaderRegister = new ShaderRegister("fs6");
		protected static const FS7:ShaderRegister = new ShaderRegister("fs7");
		
		protected var _premultAlpha:Boolean;
		protected var _textureReadParams:uint = TEXTURE_REPEAT_CLAMP | TEXTURE_FILTER_LINEAR | TEXTURE_MIP_MIPNONE;
		public function Shader3D()
		{
			if (!Shader3DFactory._allowShaderInstantion)
			{
				throw new Error("Use Shader3DFactory::getShaderInstance(shaderClass)")
			}
		}
		
		public function get premultAlpha():Boolean
		{
			return _premultAlpha;
		}
		
		public function set premultAlpha(value:Boolean):void
		{
			_premultAlpha = value;
		}
		
		public function get textureReadParams():uint
		{
			return _textureReadParams;
		}
		
		public function set textureReadParams(value:uint):void
		{
			_textureReadParams = value;
		}
		
		private var _currentShaderCode:String;
		
		private var _vertexShaderCode:String;
		final public function get vertexShaderCode():String
		{
			if (_vertexShaderCode == null)
			{
				_currentShaderCode = "";
				prepareVertexShader();
				_vertexShaderCode = _currentShaderCode;
			}
			
			return _vertexShaderCode;
		}
		
		private var _fragmentShaderCode:String;
		final public function get fragmentShaderCode():String
		{
			if (_fragmentShaderCode == null)
			{
				_currentShaderCode = "";
				prepareFragmentShader();
				_fragmentShaderCode = _currentShaderCode;
			}
			
			return _fragmentShaderCode;
		}
		
		protected function prepareVertexShader():void
		{
			multiplyVectorMatrix(VT0, VA0, VC0);
			move(V0, VA1);
			move(V1, VA2);
			move(OP, VT0);
		}
		
		protected function prepareFragmentShader():void
		{
			if ((_textureReadParams & TEXTURE_DONT_USE_TEXTURE) > 0)
			{
				writeFragmentOutput(V0);
			}
			else
			{
				writeTextureToOutput(FT1, V1, FS0, V0);
				writeFragmentOutput(FT1);
			}
		}
		
		protected function writeTextureToOutput(textureTempRegister:ShaderRegister, textureCoordsRegister:ShaderRegister, textureSampler:ShaderRegister, fragmentColorRegister:ShaderRegister):void
		{
			readTexture(textureTempRegister, textureCoordsRegister, textureSampler, _textureReadParams);
			if (_premultAlpha)
			{
				move(FT2, textureTempRegister);
				setIfEqual(FT2.x, textureTempRegister.w, FC0.x);
				add(FT2.x, textureTempRegister.w, FT2.x);
				divide(textureTempRegister.xyz, textureTempRegister.xyz, FT2.x);
			}
			multiply(textureTempRegister, textureTempRegister, fragmentColorRegister);
		}
		
		protected function writeFragmentOutput(fragmentDataRegister:ShaderRegister):void
		{
			move(OC, fragmentDataRegister);
		}
		
		public static const TEXTURE_DONT_USE_TEXTURE:int = 1;
		public static const TEXTURE_FILTER_NEAREST:int = 2;
		public static const TEXTURE_FILTER_LINEAR:int = 4;
		public static const TEXTURE_MIP_MIPNONE:int = 8;
		public static const TEXTURE_MIP_NOMIP:int = 16;
		public static const TEXTURE_MIP_MIPNEAREST:int = 32;
		public static const TEXTURE_MIP_MIPLINEAR:int = 64;
		public static const TEXTURE_REPEAT_REPEAT:int = 128;
		public static const TEXTURE_REPEAT_CLAMP:int = 256;
		public static const TEXTURE_REPEAT_WRAP:int = 512;
		
		/**
		 *  Methods
		 **/
		private function opcodeArgs1(opcode:String, dest:*, arg1:*):String
		{
			return opcode + " " + dest + ", " + arg1;
		}
		
		private function opcodeArgs2(opcode:String, dest:*, arg1:*, arg2:*):String
		{
			return opcode + " " + dest + ", " + arg1 + ", " + arg2;
		}
		
		/**
		 * mov dest, source
		 **/
		protected function move(dest:*, source:*):void
		{
			_currentShaderCode += opcodeArgs1("mov", dest, source) + "\n";
		}
		
		/**
		 * add dest, arg1, arg2
		 **/
		protected function add(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("add", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * sub dest, arg1, arg2
		 **/
		protected function subtract(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("sub", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * mul dest, arg1, arg2
		 **/
		protected function multiply(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("mul", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * div dest, arg1, arg2
		 **/
		protected function divide(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("div", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * dp3 dest, vector, vector
		 **/
		protected function dotProduct3(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("dp3", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * dp4 dest, vector, vector
		 **/
		protected function dotProduct4(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("dp4", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * m44 dest, vector, matrix
		 **/
		protected function multiplyVectorMatrix(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("m44", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * tex dest, coords, sampler <params>
		 **/
		protected function readTexture(dest:*, coords:*, sampler:*, params:uint):void
		{
			var strParams:String = "2d";
			if ((params & TEXTURE_REPEAT_CLAMP) > 0)
			{
				strParams += ", clamp";
			}
			else if ((params & TEXTURE_REPEAT_REPEAT) > 0)
			{
				strParams += ", repeat";
			}
			else if ((params & TEXTURE_REPEAT_WRAP) > 0)
			{
				strParams += ", wrap";
			}
			
			if ((params & TEXTURE_FILTER_NEAREST) > 0)
			{
				strParams += ", nearest";
			}
			else if ((params & TEXTURE_FILTER_LINEAR) > 0)
			{
				strParams += ", linear";
			}
			
			if ((params & TEXTURE_MIP_MIPNONE) > 0)
			{
				strParams += ", mipnone";
			}
			else if ((params & TEXTURE_MIP_NOMIP) > 0)
			{
				strParams += ", nomip";
			}
			else if ((params & TEXTURE_MIP_MIPNEAREST) > 0)
			{
				strParams += ", mipnearest";
			}
			else if ((params & TEXTURE_MIP_MIPLINEAR) > 0)
			{
				strParams += ", miplinear";
			}
			
			_currentShaderCode += "tex " + dest + ", " + coords + ", " + sampler + " <" + strParams + ">\n";
		}
		
		/**
		 * kil source
		 **/
		protected function kill(source:*):void
		{
			_currentShaderCode += "kil " + source + "\n";
		}
		
		/**
		 * seq dest, arg1, arg2
		 **/
		protected function setIfEqual(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("seq", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * sge dest, arg1, arg2
		 **/
		protected function setIfGreaterEqual(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("sge", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * slt dest, arg1, arg2
		 **/
		protected function setIfLess(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("slt", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * neg dest, source
		 **/
		protected function negative(dest:*, source:*):void
		{
			_currentShaderCode += opcodeArgs1("neg", dest, source) + "\n";
		}
		
		/**
		 * slt dest, arg1, arg2
		 **/
		protected function min(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("min", dest, arg1, arg2) + "\n";
		}
		
		/**
		 * slt dest, arg1, arg2
		 **/
		protected function max(dest:*, arg1:*, arg2:*):void
		{
			_currentShaderCode += opcodeArgs2("max", dest, arg1, arg2) + "\n";
		}
		
		public function prepareContext(context3D:Context3D):void
		{
			
		}
		
		public function cleanUpContext(context3D:Context3D):void
		{
			
		}
		
		private var _assembledProgram:Program3D;
		public function getAssembledProgram():Program3D
		{
			return _assembledProgram;
		}
		
		internal function setAssembledProgram(value:Program3D):void
		{
			_assembledProgram = value;
		}
	}
}
