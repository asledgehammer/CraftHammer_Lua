// Declare exposed API
type Vector = [number, number, number];

declare function findUnitsInRadius(this: void, center: Vector, radius: number): Unit[];
declare interface Unit {
    isEnemy(other: Unit): boolean;
    kill(): void;
}


// Use declared API in code
function onAbilityCast(this: void, caster: Unit, targetLocation: Vector) {
    const units = findUnitsInRadius(targetLocation, 500);
    const enemies = units.filter(unit => caster.isEnemy(unit));

    for (const enemy of enemies) {
        enemy.kill();
    }
}
