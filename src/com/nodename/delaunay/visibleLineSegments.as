package com.nodename.delaunay
{
	import com.nodename.geom.Segment;
	import flash.geom.Point;
	
	internal function visibleLineSegments(edges:Vector.<Edge>):Vector.<Segment>
	{
		var segments:Vector.<Segment> = new Vector.<Segment>();
	
		for each (var edge:Edge in edges)
		{
			if (edge.visible)
			{
				var p1:Point = edge.clippedEnds[LR.LEFT];
				var p2:Point = edge.clippedEnds[LR.RIGHT];
				segments.push(new Segment(p1, p2));
			}
		}
		
		return segments;
	}
}
	
