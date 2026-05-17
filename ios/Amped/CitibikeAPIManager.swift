//
//  CitibikeAPIManager.swift
//  Amped
//
//  Created by 0x7B5 on 8/8/23.
//

import Foundation

public struct Station: Decodable {
    let stationId: String
    let stationName: String
    let location: Location
    let totalBikesAvailable: Int
    let ebikesAvailable: Int
    let isOffline: Bool
    
    struct Location: Decodable {
        let lat: Double
        let lng: Double
    }
}

struct SupplyResponse: Decodable {
    let data: SupplyData
    
    struct SupplyData: Decodable {
        let supply: Supply
        
        struct Supply: Decodable {
            let stations: [Station]
        }
    }
}

class CitibikeAPI {
    
    private let url = URL(string: "https://citibikenyc.com/bikesharefe-gql")!
    
    func fetchStations(completion: @escaping ([Station]) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "operationName": "GetSupply",
            "variables": [
                "input": [
                    "regionCode": "BKN",
                    "rideablePageLimit": 1000
                ] as [String : Any]
            ],
            "query": """
                fragment NoticeFields on Notice {
                  localizedTitle
                  localizedDescription
                  url
                  __typename
                }

                query GetSupply($input: SupplyInput) {
                  supply(input: $input) {
                    stations {
                      stationId
                      stationName
                      location {
                        lat
                        lng
                      }
                      bikesAvailable
                      bikeDocksAvailable
                      ebikesAvailable
                      scootersAvailable
                      totalBikesAvailable
                      totalRideablesAvailable
                      isValet
                      isOffline
                      notices {
                        ...NoticeFields
                      }
                      siteId
                      lastUpdatedMs
                    }
                    notices {
                      ...NoticeFields
                    }
                    requestErrors {
                      ...NoticeFields
                      __typename
                    }
                  }
                }
            """
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("API call failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let supplyResponse = try JSONDecoder().decode(SupplyResponse.self, from: data)
                let stations = supplyResponse.data.supply.stations
                completion(stations)
            } catch {
                print("Failed to decode JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    struct StationCategories {
        let emptyStations: [Station]
        let ebikeOnlyStations: [Station]
        let oneClassicStations: [Station]
    }
    
    func categorizeStations(stations: [Station]) -> StationCategories {
        var emptyStations = [Station]()
        var ebikeOnlyStations = [Station]()
        var oneClassicStations = [Station]()
        
        for station in stations {
            if station.isOffline { continue }
            
            if station.totalBikesAvailable == 0 {
                emptyStations.append(station)
            } else if station.totalBikesAvailable == station.ebikesAvailable {
                ebikeOnlyStations.append(station)
            } else {
                let classicBikesAvailable = station.totalBikesAvailable - station.ebikesAvailable
                if classicBikesAvailable == 1 {
                    oneClassicStations.append(station)
                }
            }
        }
        
        return StationCategories(
            emptyStations: emptyStations,
            ebikeOnlyStations: ebikeOnlyStations,
            oneClassicStations: oneClassicStations
        )
    }
}
