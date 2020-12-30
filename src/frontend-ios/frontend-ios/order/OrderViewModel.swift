//
//  OrderViewModel.swift
//  frontend-ios
//
//  Created by Fabijan Bajo on 21/11/2020.
//

import RxSwift
import RxCocoa

protocol OrderViewModelInput {
    var viewWillAppear: Observable<Void> { get }
}

protocol OrderViewModelOutput {
    var order: Driver<Order> { get }
}

internal struct OrderViewModel {
    typealias Dependencies = CartServiceDependency & CatalogServiceDependency

    let dependencies: Dependencies
    let order: Order

    init(_ dependencies: Dependencies, order: Order) {
        self.dependencies = dependencies
        self.order = order
    }
}

extension OrderViewModel: ReactiveTransforming {
    struct Input: OrderViewModelInput {
        var viewWillAppear: Observable<Void>
    }
    struct Output: OrderViewModelOutput {
        var order: Driver<Order>
    }

    func transform(_ input: Input) -> Output {
        let order = input.viewWillAppear
            .flatMapLatest {
                MicroserviceClient.execute(OrderRequest.GetOne(order: self.order))
                    .asDriver(onErrorJustReturn: Order.empty())
            }
            .asDriver(onErrorJustReturn: Order.empty())
            .flatMapLatest { order -> Driver<Order> in
                return dependencies.catalogService.getProducts(for: order)
                    .map { populated(order, with: $0) }
                    .asDriver(onErrorJustReturn: Order.empty())
            }
            .asDriver(onErrorJustReturn: Order.empty())

        return Output(
            order: order
        )
    }

    private func populated(_ order: Order, with products: [Product]) -> Order {
        let items = order.items.map { item -> OrderItem in
            guard let product = products.first(where: { $0.productid == item.productid }) else {
                return item
            }
            var updating = item
            updating.product = product

            return updating
        }
        var newOrder = order
        newOrder.items = items

        return newOrder
    }
}
