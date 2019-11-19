package com.nodename.delaunay
{
	import com.nodename.geom.Segment;
	
	internal function delaunayLinesForEdges(edges:Vector.<Edge>):Vector.<Segment>
	{
		var segments:Vector.<Segment> = new Vector.<Segment>();
		for each (var edge:Edge in edges)
		{
			segments.push(edge.delaunayLine());
		}
		return segments;
	}
}
	
