//
//  NetworkService.swift
//  testOrderToDeliveryApp
//
//  Created by Админ on 24.11.2022.
//

import Foundation



/// создаем структуру для создания запроса
struct NetworkService {
    
    static let shared = NetworkService()
    private init() {}
    
    func fetchAllCategories(complition: @escaping(Result<AllDishes,Error>) -> Void){
        request(route: .fetchAllCategories, method: .get, completion: complition)
    }
    
    
    /// - Parameters:
    ///   - route: <#route description#>
    ///   - method: <#method description#>
    ///   - parameters: <#parameters description#>
    ///   - type: <#type description#>
    ///   - completion: <#completion description#>
    private func request<T: Decodable>(route: Route,
                                     method: Method,
                                     parameters: [String:Any]? = nil,
                                     completion: @escaping (Result<T,Error>) -> Void) {
        
        guard let request = createRequest(route: route, method: method, parametrs: parameters) else {completion(.failure(AppError.unknownError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            var result: Result<Data, Error>?
            if let data =  data {
                result = .success(data)
                let responseString = String(data: data, encoding: .utf8) ?? "Не могу пробразовать дату в строку"
                //print("The response is: \(responseString)")
            } else if let error = error {
                result = .failure(error)
                print("The error is : \(error.localizedDescription)")
                
            }
            
            DispatchQueue.main.async {
                self.handleResponse(result: result, completion: completion)
            }
            
        }.resume()
        
    }
    
    
    
    private func handleResponse<T:Decodable>(result:Result<Data, Error>?,
                                             completion: (Result<T,Error>) -> Void) {
        guard let result = result else {
            completion(.failure(AppError.unknownError))
            return
        }
        switch result {
        case .success(let data):
            let decoder = JSONDecoder()
            guard let response = try? decoder.decode(ApiRespons<T>.self, from: data) else {
                
                completion(.failure(AppError.errorDecoding))
                return
            }
            
            if let error = response.error {
                completion(.failure(AppError.serverError(error)))
            }
            
            if let decodedData = response.data {
                completion(.success(decodedData))
                
            } else {
                completion(.failure(AppError.unknownError))
            }
            
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    
    /// функция создания запроса с вводными параметрами.
    /// - Parameters:
    ///   - route: это путь к к точке в бэке которую мы хотим получить.
    ///   - method: тип запроса который будем делать.
    ///   - parametrs: параметры которые мы будем передавать на серверную часть(может быть нил)
    /// - Returns: description
    private func createRequest(route: Route,
                               method: Method,
                               parametrs: [String: Any]? = nil) -> URLRequest? {
        let urlString = Route.baseUrl + route.description
        guard let url = urlString.asUrl else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = method.rawValue
        if let params = parametrs {
            switch method{
            case .get:
                var urlComponents = URLComponents(string: urlString)
                urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)")}
                urlRequest.url = urlComponents?.url
            case .post, .delete, .patch:
                let bodyData = try? JSONSerialization.data(withJSONObject: params )
                urlRequest.httpBody = bodyData
            }
        }
        
        return urlRequest
    }
    
}
