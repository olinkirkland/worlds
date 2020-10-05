package layers.geography.hydrology
{
    import global.Sort;

    import graph.Cell;

    import ui.Settings;

    public class Hydrology
    {
        private var map:Map;
        public var rivers:Vector.<River>;

        public function Hydrology(map:Map)
        {
            this.map = map;
            rivers = new Vector.<River>();

            makeRivers();
        }

        private function makeRivers():void
        {
            // Pour flux to lowest neighbors and determine rivers
            map.cells.sort(Sort.cellByElevation).reverse();
            for each (var cell:Cell in map.cells)
                if (!cell.ocean)
                    pour(cell, cell.lowestNeighborBelow);

            stretchMoisture();
            for each (var river:River in rivers)
            {
                var m:Number = river.cells[river.cells.length - 1].moisture;
                for each (cell in river.cells)
                    cell.moisture = 1;
            }

            averageMoisture();
            //stretchMoisture();
        }

        private function pour(c:Cell, t:Cell):void
        {
            if (!t) return;

            t.flux += c.flux;
            if (c.flux > 10)
            {
                if (c.rivers.length == 0)
                {
                    // Start new river
                    river = new River();
                    rivers.push(river);
                    river.cells.push(c, t);

                    // todo register feature: source
                }
                else
                {
                    // Extend an existing river and pick the longest river to continue
                    var longestRiver:River = c.rivers[0];
                    for each (var river:River in rivers)
                        if (river.cells.length > river.cells.length)
                            longestRiver = river;

                    longestRiver.addCell(t);

                    // todo register Geofeature: confluence
                }

                if (t.ocean)
                {
                    // todo register Geofeature: estuary here
                }
            }
        }

        private function averageMoisture():void
        {
            for (var i:int = 0; i < 3; i++)
            {
                for each (var cell:Cell in map.cells)
                {
                    if (cell.ocean)
                        continue;

                    var average:Number = 0;
                    var neighborCount:int = 0;
                    for each (var neighbor:Cell in cell.neighbors)
                        if (neighbor.moisture)
                        {
                            average += neighbor.moisture;
                            neighborCount++;
                        }

                    cell.moisture = average /= neighborCount;
                }
            }

            for each (cell in map.cells)
                if (!cell.moisture)
                    cell.moisture = 0;
        }

        private function stretchMoisture():void
        {
            var maxMoisture:Number = 0;
            for each (var cell:Cell in map.cells)
                if (cell.moisture > maxMoisture)
                    maxMoisture = cell.moisture;

            for each (cell in map.cells)
                if (cell.moisture)
                    cell.moisture *= (1 / maxMoisture);
        }

        public function removeRiver(river:River):void
        {
            river.removeAllCells();

            for (var i:int = 0; i < rivers.length; i++)
                if (rivers[i] == river)
                    rivers.removeAt(i);
        }

        public function validateRiver(river:River):void
        {
            if (!river.end.lowestNeighborBelow ||
                    (river.type == River.STEM && river.cells.length < Settings.properties.riverMinimumStemLength) ||
                    (river.type == River.TRIBUTARY && river.cells.length < Settings.properties.riverMinimumTributaryLength))
                removeRiver(river);
        }
    }
}