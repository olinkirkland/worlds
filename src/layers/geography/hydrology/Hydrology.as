package layers.geography.hydrology
{
    import layers.geography.*;
    import ui.Settings;

    public class Hydrology
    {
        private var map:Map;
        public var rivers:Vector.<River>;

        public function Hydrology(map:Map)
        {
            this.map = map;
            rivers = new Vector.<River>();
        }

        public function addRiver():River
        {
            var river:River = new River();
            river.type = River.STEM;
            river.index = rivers.length;
            rivers.push(river);
            return river;
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
                    (river.type == River.STEM && river.cells.length < Settings.advancedProperties.riverMinimumStemLength) ||
                    (river.type == River.TRIBUTARY && river.cells.length < Settings.advancedProperties.riverMinimumTributaryLength))
                removeRiver(river);
        }
    }
}