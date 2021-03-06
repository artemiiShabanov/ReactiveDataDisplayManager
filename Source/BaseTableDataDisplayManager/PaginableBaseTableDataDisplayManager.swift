//
//  PaginableBaseTableDataDisplayManager.swift
//  ReactiveDataDisplayManager
//
//  Created by Ivan Smetanin on 27/05/2018.
//  Copyright © 2018 Александр Кравченков. All rights reserved.
//

import Foundation
import CoreEvents

open class PaginableBaseTableDataDisplayManager: BaseTableDataDisplayManager {

    /// Called if table shows last cell
    public var lastCellShowingEvent = FutureEmptyEvent()

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSectionIndex = cellGenerators.count - 1
        let lastCellInLastSectionIndex = cellGenerators[lastSectionIndex].count - 1
        let lastCellIndexPath = IndexPath(row: lastCellInLastSectionIndex, section: lastSectionIndex)
        if indexPath == lastCellIndexPath {
            lastCellShowingEvent.invoke(with: ())
        }
    }

}
