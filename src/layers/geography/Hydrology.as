package layers.geography {
    import global.Util;

    import graph.Cell;

    public class Hydrology {
        private var map:Map;

        public function Hydrology(map:Map) {
            this.map = map;

            /**
             * Precipitation
             */

            // Apply water to cells from precipitation
            for each (var cell:Cell in map.cells)
                cell.water += cell.precipitation;

            /**
             * Runoff
             */


        }
    }
}