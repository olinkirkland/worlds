package layers.geography {
    import graph.Cell;

    public class Hydrology {
        private var map:Map;
        public var rivers:Vector.<River>;

        public function Hydrology(map:Map) {
            this.map = map;
            rivers = new Vector.<River>();
        }

        public function addRiver():River {
            var river:River = new River();
            river.index = rivers.length;
            rivers.push(river);
            return river;
        }

        public function precipitate():void {
            for each (var cell:Cell in map.cells)
                cell.water += cell.precipitation;
        }
    }
}