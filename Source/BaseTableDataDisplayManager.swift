//
//  BaseTableDataDisplayManager.swift
//  ReactiveDataDisplayManager
//
//  Created by Alexander Kravchenkov on 01.08.17.
//  Copyright © 2017 Alexander Kravchenkov. All rights reserved.
//

import Foundation
import UIKit

/// Contains base implementation of DataDisplayManager with UITableView.
/// Registers nibs, determinates EstimatedRowHeight.
/// Can fill table with user data.
open class BaseTableDataDisplayManager: NSObject, DataDisplayManager {

    // MARK: - Typealiases

    public typealias CollectionType = UITableView
    public typealias CellGeneratorType = TableCellGenerator
    public typealias HeaderGeneratorType = TableHeaderGenerator

    // MARK: - Events

    /// Called if table scrolled
    public var scrollEvent = BaseEvent<UITableView>()
    public var scrollViewWillEndDraggingEvent: BaseEvent<CGPoint>

    // MARK: - Fileprivate properties

    fileprivate(set) var cellGenerators: [TableCellGenerator]
    fileprivate var sectionHeaderGenerator: [TableHeaderGenerator]
    fileprivate weak var tableView: UITableView?
    fileprivate let estimatedHeight: CGFloat

    // MARK: - Initialization and deinitialization

    public init(estimatedHeight: CGFloat = 40, collection: UITableView? = nil) {
        self.estimatedHeight = estimatedHeight
        self.cellGenerators = [TableCellGenerator]()
        self.sectionHeaderGenerator = [TableHeaderGenerator]()
        self.scrollViewWillEndDraggingEvent = BaseEvent<CGPoint>()
        super.init()
    }
}

// MARK: - Generator actions

extension BaseTableDataDisplayManager {

    /// It causes register nib for all generators.
    public func set(collection: UITableView) {
        self.tableView = collection
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.cellGenerators.forEach { collection.registerNib($0.identifier) }
    }

    public func addSectionHeaderGenerator(_ generator: TableHeaderGenerator) {
        self.sectionHeaderGenerator.append(generator)
    }

    public func addCellGenerator(_ generator: TableCellGenerator) {
        self.tableView?.registerNib(generator.identifier)
        self.cellGenerators.append(generator)
    }

    public func addCellGenerators(_ generators: [TableCellGenerator]) {
        generators.forEach { self.tableView?.registerNib($0.identifier) }
        self.cellGenerators.append(contentsOf: generators)
    }

    /// Adds a new cell generator.
    ///
    /// - Parameters:
    ///   - generator: New cell generator.
    ///   - after: Generator after which generator should be added.
    ///   - needRegister: Pass true to register the cell nib.
    public func addCellGenerator(_ generator: TableCellGenerator, after: TableCellGenerator? = nil) {

        guard let guardedAfter = after else {
            self.addCellGenerator(generator)
            return
        }

        self.tableView?.registerNib(generator.identifier)

        guard let index = self.cellGenerators.index(where: { $0 === guardedAfter }) else {
            fatalError("Fatal Error in \(#function). You tried to add generators after unexisted generator")
        }
        self.cellGenerators.insert(generator, at: index + 1)
    }

    /// Adds a new array of cell generators.
    ///
    /// - Parameters:
    ///   - generator: New cell generators.
    ///   - after: Generator after which generators should be added.
    ///   - needRegister: Pass true to register the cell nib.
    public func addCellGenerators(_ generators: [TableCellGenerator], after: TableCellGenerator? = nil) {

        guard let guardedAfter = after else {
            self.addCellGenerators(generators)
            return
        }

        generators.forEach { self.tableView?.registerNib($0.identifier) }

        guard let index = self.cellGenerators.index(where: { $0 === guardedAfter }) else {
            fatalError("Fatal Error in \(#function). You tried to add generators after unexisted generator")
        }
        self.cellGenerators.insert(contentsOf: generators, at: index + 1)
    }

    public func clearCellGenerators() {
        self.cellGenerators.removeAll()
    }

    public func clearHeaderGenerators() {
        self.sectionHeaderGenerator.removeAll()
    }

    public func move(generator: CellGeneratorType, on offset: Int, needsMoveRow: Bool = true) {
        guard let index = cellGenerators.firstIndex(where: { $0 === generator }),
            index + offset < self.cellGenerators.count,
            let tableView = self.tableView else {
                return
        }

        let newIndex = index + offset

        let oldValue = self.cellGenerators[index]
        print(index)
        print(newIndex)
        self.cellGenerators.remove(at: index)
        self.cellGenerators.insert(oldValue, at: newIndex)
        if needsMoveRow {
            self.tableView?.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: newIndex, section: 0))
        }
    }

    public func forceRefill() {
        self.tableView?.reloadData()
    }
}

// MARK: - TableView actions

public extension BaseTableDataDisplayManager {

    /// Removes generator from adapter. Generators compare by references.
    ///
    /// - Parameters:
    ///   - generator: Generator to delete.
    ///   - animation: Animation for row action.
    ///   - scrollPosition: If not nil than performs scroll before removing generator.
    /// A constant that identifies a relative position in the table view (top, middle, bottom)
    /// for row when scrolling concludes. See UITableViewScrollPosition for descriptions of valid constants.
    public func remove(_ generator: TableCellGenerator, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {
        guard let index = self.cellGenerators.index(where: { $0 === generator }) else { return }
        self.removeGenerator(with: index, with: animation, needScrollAt: scrollPosition)
    }

    /// Inserts new generator after last generator.
    ///
    /// - Parameters:
    ///   - newGenerator: Generator wihics you wont to insert after last generator.
    ///   - animation: Animation for row action.
    ///   - scrollPosition: If not nil than performs scroll before removing generator.
    /// A constant that identifies a relative position in the table view (top, middle, bottom)
    /// for row when scrolling concludes. See UITableViewScrollPosition for descriptions of valid constants.
    public func insert(new newGenerator: TableCellGenerator, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {
        let index = self.cellGenerators.count
        self.insertGenerator(newGenerator, at: index, with: animation, needScrollAt: scrollPosition)
    }

    public func `switch`(new newGenerator: TableCellGenerator, and oldGenerator: TableCellGenerator, removeAnimation: UITableView.RowAnimation = .automatic, insertAnimation: UITableView.RowAnimation = .automatic) {
        guard let index = self.cellGenerators.index(where: { $0 === oldGenerator }) else { return }

        guard let table = self.tableView else { return }

        table.beginUpdates()
        self.cellGenerators.remove(at: index)
        self.cellGenerators.insert(newGenerator, at: index)
        let indexPath = IndexPath(row: index, section: 0)
        table.deleteRows(at: [indexPath], with: removeAnimation)
        table.insertRows(at: [indexPath], with: insertAnimation)
        table.endUpdates()
    }
    
    public func insert(new newGenerators: [TableCellGenerator], after generator: TableCellGenerator, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {
        guard let index = self.cellGenerators.index(where: { $0 === generator }) else { return }

        guard let table = self.tableView else { return }
        newGenerators.forEach({ table.registerNib($0.identifier) })

        table.registerNib(generator.identifier)
        table.beginUpdates()
        self.cellGenerators.insert(contentsOf: newGenerators, at: index + 1)
        var mutableIndex = index + 1
        let indexPathes = newGenerators.map({ (generator) -> IndexPath in
            let result = IndexPath(row: mutableIndex, section: 0)
            mutableIndex += 1
            return result
        })
        table.insertRows(at: indexPathes, with: animation)
        table.endUpdates()
        if let scrollPosition = scrollPosition, let lastIndex = indexPathes.last {
            table.scrollToRow(at: lastIndex, at: scrollPosition, animated: true)
        }
    }

    /// Inserts new generator after current generator.
    ///
    /// - Parameters:
    ///   - generator: Current generator. Must contained this adapter.
    ///   - newGenerator: Generator wihics you wont to insert after current generator.
    ///   - animation: Animation for row action.
    ///   - scrollPosition: If not nil than performs scroll before removing generator.
    /// A constant that identifies a relative position in the table view (top, middle, bottom)
    /// for row when scrolling concludes. See UITableViewScrollPosition for descriptions of valid constants.
    public func insert(after generator: TableCellGenerator, new newGenerator: TableCellGenerator, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {
        guard let index = self.cellGenerators.index(where: { $0 === generator }) else { return }

        self.insertGenerator(newGenerator, at: index + 1, with: animation, needScrollAt: scrollPosition)
    }

    /// Inserts new generator before current generator.
    ///
    /// - Parameters:
    ///   - generator: Current generator. Must contained this adapter.
    ///   - newGenerator: Generator wihics you wont to insert before current generator.
    ///   - animation: Animation for row action.
    ///   - scrollPosition: If not nil than performs scroll before removing generator.
    /// A constant that identifies a relative position in the table view (top, middle, bottom)
    /// for row when scrolling concludes. See UITableViewScrollPosition for descriptions of valid constants.
    public func insert(before generator: TableCellGenerator, new newGenerator: TableCellGenerator, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {
        guard let index = self.cellGenerators.index(where: { $0 === generator }) else { return }
        if index == 0 {
            self.insertFirst(generator: newGenerator, with: animation)
        } else {
            self.insertGenerator(newGenerator, at: index - 1 == 0 ? 1 : index - 1, with: animation, needScrollAt: scrollPosition)
        }
    }

    public func insertFirst(generator: TableCellGenerator, with animation: UITableView.RowAnimation = .automatic) {
        self.insertGenerator(generator, at: 0, with: animation)
    }

    /// Swaps two adapter between each other.
    ///
    /// - Warning: Calls reload data in tableView.
    ///
    /// - Parameters:
    ///   - firstGenerator: Generator which must to move to new place. Must contins in adapter.
    ///   - secondGenerator: Generator which must to replaced with firstGenerator and move to it place.
    /// Must contains id adapter.
    public func swap(firstGenerator: TableCellGenerator, with secondGenerator: TableCellGenerator) {
        guard let firstIndex = self.cellGenerators.index(where: { $0 === firstGenerator }),
            let secondIndex = self.cellGenerators.index(where: { $0 === secondGenerator })
            else { return }

        self.cellGenerators.remove(at: firstIndex)
        self.cellGenerators.remove(at: secondIndex)

        self.cellGenerators.insert(firstGenerator, at: secondIndex)
        self.cellGenerators.insert(secondGenerator, at: firstIndex)

        self.tableView?.reloadData()
    }
}

// MARK: - Private methods

private extension BaseTableDataDisplayManager {

    func insertGenerator(_ generator: TableCellGenerator, at index: Int, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {

        guard let table = self.tableView else { return }

        table.registerNib(generator.identifier)
        table.beginUpdates()
        self.cellGenerators.insert(generator, at: index)
        let indexPath = IndexPath(row: index, section: 0)
        table.insertRows(at: [indexPath], with: animation)
        table.endUpdates()
        if let scrollPosition = scrollPosition {
            table.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        }
    }

    func removeGenerator(with index: Int, with animation: UITableView.RowAnimation = .automatic, needScrollAt scrollPosition: UITableView.ScrollPosition? = nil) {

        guard let table = self.tableView else { return }

        if index > 0 {
            let previousIndexPath = IndexPath(row: index - 1, section: 0)
            if let scrollPosition = scrollPosition {
                table.scrollToRow(at: previousIndexPath, at: scrollPosition, animated: true)
            }
        }
        table.beginUpdates()
        self.cellGenerators.remove(at: index)
        let indexPath = IndexPath(row: index, section: 0)
        table.deleteRows(at: [indexPath], with: animation)
        table.endUpdates()
    }

}

// MARK: - UITableViewDelegate

extension BaseTableDataDisplayManager: UITableViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let guardTable = self.tableView else { return }
        self.scrollEvent.invoke(with: guardTable)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.estimatedHeight
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > self.sectionHeaderGenerator.count - 1 {
            return nil
        }

        return self.sectionHeaderGenerator[section].generate()
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > self.sectionHeaderGenerator.count - 1 {
            return 0.01
        }
        return self.sectionHeaderGenerator[section].height(tableView, forSection: section)
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectable = self.cellGenerators[indexPath.row] as? SelectableItem else { return }
        selectable.didSelectEvent.invoke(with: ())
        if selectable.isNeedDeselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.scrollViewWillEndDraggingEvent.invoke(with: velocity)
    }
}

// MARK: - UITableViewDataSource

extension BaseTableDataDisplayManager: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaderGenerator.isEmpty ? 1 : sectionHeaderGenerator.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellGenerators.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.cellGenerators[indexPath.row].generate(tableView: tableView, for: indexPath)
    }
}

