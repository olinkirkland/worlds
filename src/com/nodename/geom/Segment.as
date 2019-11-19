package com.nodename.geom
{
	import flash.geom.Point;
	
	public final class Segment extends Object
	{
		public static function compareLengths_MAX(segment0:Segment, segment1:Segment):Number
		{
			var length0:Number = Point.distance(segment0.p0, segment0.p1);
			var length1:Number = Point.distance(segment1.p0, segment1.p1);
			if (length0 < length1)
			{
				return 1;
			}
			if (length0 > length1)
			{
				return -1;
			}
			return 0;
		}
		
		public static function compareLengths(edge0:Segment, edge1:Segment):Number
		{
			return - compareLengths_MAX(edge0, edge1);
		}

		public var p0:Point;
		public var p1:Point;
		
		public function Segment(p0:Point, p1:Point)
		{
			super();
			this.p0 = p0;
			this.p1 = p1;
		}
		
	}
}