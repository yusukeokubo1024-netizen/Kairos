import { Location } from "../types";
export declare class LocationService {
    static updateLocation(userId: string, latitude: unknown, longitude: unknown, accuracy?: unknown): Promise<Location>;
    static getLocation(requesterId: string, userId: string): Promise<Location>;
    static setSharedWith(userId: string, sharedWith: unknown): Promise<void>;
    static listSharedLocations(userId: string): Promise<Location[]>;
}
//# sourceMappingURL=locationService.d.ts.map