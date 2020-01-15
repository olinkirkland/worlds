package layers {
import flash.utils.Dictionary;

import global.Global;
import global.Rand;
import global.Util;

import graph.*;

public class Lithosphere {
    private static var tectonicPowerImbalance:int = 0;

    private var map:Map;

    public var tectonicPlates:Object = {};
    public var totalArea:Number;

    public function Lithosphere(map:Map) {
        this.map = map;

        pickStartingCells(Global.rand.between(10,
                15));
        expandPlates();
    }


    private function pickStartingCells(plateCount:int):void {
        for (var i:int = 0; i < plateCount; i++) {
            var cell:Cell = map.cells[int(Global.rand.next() * map.cells.length)];

            if (!cell.tectonicPlate) {
                var t:TectonicPlate = new TectonicPlate(i);
                tectonicPlates[t.index] = t;
                t.addCell(cell);
                cell.tectonicPlatePower = Global.rand.next() * tectonicPowerImbalance;
            }
        }
    }


    private function expandPlates():void {
        var n:int = 1;
        for each (var tectonicPlate:TectonicPlate in tectonicPlates) {
            var t:Date = new Date();
            Util.log("> Making tectonic plate (" + (n++) + ")...");

            map.unuseCells();
            var queue:Vector.<Cell> = new Vector.<Cell>();
            // There's only one cell in here right now
            if (tectonicPlate.cells.length > 0) {
                queue.push(tectonicPlate.cells[0]);
            }

            while (queue.length > 0) {
                var cell:Cell = queue.shift();
                for each (var neighbor:Cell in cell.neighbors) {
                    if (!neighbor.used && neighbor.tectonicPlate != cell.tectonicPlate && neighbor.tectonicPlatePower < cell.tectonicPlatePower) {
                        neighbor.tectonicPlatePower = cell.tectonicPlatePower - (Global.rand.next() > .5 ? Global.rand.next() * 10 : 0);
                        if (neighbor.tectonicPlate) {
                            neighbor.tectonicPlate.removeCell(neighbor);
                        }

                        tectonicPlate.addCell(neighbor);
                        queue.push(neighbor);
                        neighbor.used = true;
                    }
                }
            }

            Util.log("  " + Util.secondsSince(t));
        }

        // Ensure there are no tectonic plate fragments
        var pass:int = 0;
        do {
            var fragments:Vector.<Cell> = getPlateFragments();

            t = new Date();
            Util.log("> Removing tectonic fragments (" + fragments.length + ")...");

            for (var i:int = 0; i < fragments.length; i++) {
                cell = fragments[i];
                var neighbors:Vector.<Cell> = cell.neighbors.concat();
                while (neighbors.length > 0) {
                    neighbor = Cell(neighbors.removeAt(int(Global.rand.next() * neighbors.length)));
                    if (cell.tectonicPlate != neighbor.tectonicPlate) {
                        cell.tectonicPlate.removeCell(cell);
                        neighbor.tectonicPlate.addCell(cell);
                        fragments.removeAt(i--);
                        break;
                    }
                }
            }
            pass++;
            Util.log("  " + Util.secondsSince(t));
        } while (getPlateFragments().length > 0 && pass < 10);

        // Determine the tectonic plate borders
        t = new Date();
        Util.log("> Determining tectonic plate borders...");
        var borderCells:Vector.<Cell> = new Vector.<Cell>();
        for each (cell in map.cells) {
            for each (neighbor in cell.neighbors) {
                if (cell.tectonicPlate != neighbor.tectonicPlate) {
                    cell.tectonicPlateBorder = true;
                    borderCells.push(cell);
                }
            }
        }

        // Calculate the area for each tectonic plate
        t = new Date();
        Util.log("> Calculating tectonic plate area...");
        totalArea = 0;
        for each (tectonicPlate in tectonicPlates) {
            tectonicPlate.calculateArea();
            totalArea += tectonicPlate.area;
        }
        for each (tectonicPlate in tectonicPlates)
            tectonicPlate.areaPercent = Util.round(tectonicPlate.area / totalArea);
        Util.log("  " + Util.secondsSince(t));

        // Set plates to either oceanic or continental
        t = new Date();
        Util.log("> Determining tectonic plate types and setting their heights...");
        var platesArray:Array = Util.toArray(tectonicPlates);
        platesArray.sortOn("area");
        var currentAreaPercent:Number = 0;
        for each (tectonicPlate in platesArray) {
            tectonicPlate.type = currentAreaPercent < .3 ? TectonicPlate.CONTINENTAL : TectonicPlate.OCEANIC;
            currentAreaPercent += tectonicPlate.areaPercent;
        }

        for each (tectonicPlate in platesArray) {

            var height:Number = 0;
            if (tectonicPlate.type == TectonicPlate.CONTINENTAL)
                height = Global.rand.between(.3, .5);
            else if (tectonicPlate.type == TectonicPlate.OCEANIC)
                height = Global.rand.between(.1, .3);
            for each(cell in tectonicPlate.cells)
                cell.height = height;
        }
        Util.log("  " + Util.secondsSince(t));

        // Set initial heights for borders
        // Cells pointing toward an edge will create a mountain
        // Cells pointing away from an edge will create a trench
        t = new Date();
        Util.log("> Setting initial heights for tectonic plate borders...");
        for each (cell in borderCells) {
            // Determine the cell's height based on its neighbors
            var changedHeight:Number = 0;
            var margin:int = 45;
            for each (neighbor in cell.neighbors) {
                if (cell.tectonicPlate != neighbor.tectonicPlate) {
                    var chance:Number = cell.tectonicPlate.type == TectonicPlate.OCEANIC ? 0.2 : 1;
                    if (Global.rand.next() > chance)
                        break;

                    var edge:Edge = cell.sharedEdge(neighbor);
                    if (edge) {
                        var degreesToNeighbor:int = Util.angleBetweenTwoPoints(cell.point, neighbor.point);
                        var difference:int = Util.differenceBetweenTwoDegrees(cell.tectonicPlateDirection, degreesToNeighbor);
                        if (difference > 360 - margin || difference < 0 + margin) {
                            cell.height = 1;
                            break;
                        }
                        if (difference > 180 - margin && difference < 180 + margin) {
                            cell.height = 0;
                            break;
                        }
                    }
                }
            }
        }
        Util.log("  " + Util.secondsSince(t));
    }


    private function getPlateFragments():Vector.<Cell> {
        map.unuseCells();

        // Fragments are Cells that are not connected to the largest plate body with the same index
        // Determine plate bodies
        var bodies:Array = [];
        var queue:Vector.<Cell> = new Vector.<Cell>();
        var cell:Cell = map.cells[0];
        cell.used = true;
        queue.push(map.cells[0]);
        var currentTectonicPlate:TectonicPlate = cell.tectonicPlate;
        var currentBody:Vector.<Cell> = new Vector.<Cell>();

        while (queue.length > 0) {
            cell = queue.shift();
            currentBody.push(cell);

            for each (var neighbor:Cell in cell.neighbors) {
                if (!neighbor.used && neighbor.tectonicPlate == cell.tectonicPlate) {
                    neighbor.used = true;
                    queue.push(neighbor);
                }
            }

            if (queue.length == 0) {
                // Empty
                bodies.push(currentBody);
                currentBody = new Vector.<Cell>();
                cell = map.nextUnusedCell();
                if (cell) {
                    currentTectonicPlate = cell.tectonicPlate;
                    queue.push(cell);
                    cell.used = true;
                }
            }
        }

        // Determine the fragments by identifying the smallest bodies with a corresponding body belonging to the same tectonic plate
        var fragments:Vector.<Cell> = new Vector.<Cell>();
        var bodiesDictionary:Dictionary = new Dictionary();
        for each (var body:Vector.<Cell> in bodies) {
            var t:TectonicPlate = Cell(body[0]).tectonicPlate;
            // Largest body is the largest body of that tectonic plate
            if (!bodiesDictionary[t]) {
                bodiesDictionary[t] = body;
            } else {
                var bodyInDictionary:Vector.<Cell> = bodiesDictionary[t];
                if (body.length > bodyInDictionary.length) {
                    fragments = fragments.concat(bodyInDictionary);
                    bodiesDictionary[t] = body;
                } else {
                    fragments = fragments.concat(body);
                }
            }
        }

        return fragments;
    }
}
}