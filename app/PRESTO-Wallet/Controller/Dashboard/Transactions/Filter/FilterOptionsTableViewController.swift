//
//  FilterOptionsTableViewController.swift
//  PRESTO-Wallet
//
//  Created by Jeffrey on 2018-01-06.
//  Copyright © 2018 JeffreyCA. All rights reserved.
//

import MZFormSheetPresentationController
import UIKit

protocol FilterOptionsDelegate: class {
    func updateFilterOptions(filterOptions: FilterOptions?)
}

class FilterOptionsTableViewController: UITableViewController {
    @IBOutlet weak var selectedAgenciesLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!

    // Used to expand/collapse date pickers
    private var isStartDatePickerVisible = false
    private var isEndDatePickerVisible = false
    weak var delegate: FilterOptionsDelegate?
    var filterOptions: FilterOptions?

    private enum Constants {
        static let MINIMUM_FILTER_YEARS_AGO: Int = 2
        static let DEFAULT_START_MONTHS_AGO: Int = 6
        static let DATE_TODAY_HINT: String = " (Today)"

        static let ALL_SELECTED: String = "All"
        static let SELECTED_AGENCIES_HINT: String = " Selected"

        static let START_DATE_PICKER_ROW = 2
        static let END_DATE_PICKER_ROW = 4
    }

    @IBAction func resetDialog() {
        initializeDatePickers()
        resetSelectedAgencies()

        updateFilterOptionsDates()
        updateDateText()
        updateSelectedAgenciesText()
    }

    @IBAction func finishDialog() {
        delegate?.updateFilterOptions(filterOptions: filterOptions)
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction
    public func didChangeDate() {
        updateMinMaxDates()
        updateDateText()
        updateFilterOptionsDates()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDatePickers()

        if filterOptions == nil {
            filterOptions = FilterOptions(startDate: startDatePicker.date, endDate: endDatePicker.date, agencies: createTransitAgencyArray())
        }

        updateDateText()
        updateSelectedAgenciesText()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Prepare")
        let destination = segue.destination as? SelectTransitAgencyTableViewController
        destination?.delegate = self
        destination?.filterOptions = filterOptions
    }
}

// Configure date picker and date labels
extension FilterOptionsTableViewController {
    // Create array of all transit agencies set to enabled
    private func createTransitAgencyArray() -> [FilterTransitAgency] {
        var array = [FilterTransitAgency]()
        TransitAgency.allCases.forEach({
            array.append(FilterTransitAgency(agency: $0, enabled: true))
        })

        return array
    }

    private func initializeDatePickers() {
        let today = Date()
        let defaultStartDate = Calendar.current.date(byAdding: .month, value: -Constants.DEFAULT_START_MONTHS_AGO, to: today)
        let minimumDate = Calendar.current.date(byAdding: .year, value: -Constants.MINIMUM_FILTER_YEARS_AGO, to: today)

        startDatePicker.minimumDate = minimumDate
        endDatePicker.minimumDate = minimumDate
        startDatePicker.maximumDate = today
        endDatePicker.maximumDate = today

        if let defaultStartDate = defaultStartDate {
            startDatePicker.date = defaultStartDate
        }

        endDatePicker.date = today
    }

    private func toggleStartDatePicker() {
        isStartDatePickerVisible = !isStartDatePickerVisible
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

    private func toggleEndDatePicker() {
        isEndDatePickerVisible = !isEndDatePickerVisible
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

    private func resetSelectedAgencies() {
        filterOptions?.agencies = createTransitAgencyArray()
    }

    private func updateDateText() {
        startDateLabel.text = DateFormatter.localizedString(from: startDatePicker.date, dateStyle: .long, timeStyle: .none)
        endDateLabel.text = DateFormatter.localizedString(from: endDatePicker.date, dateStyle: .long, timeStyle: .none)

        // Append "(Today)" hint to end of date text if date is today
        if Calendar.current.isDateInToday(startDatePicker.date) {
            startDateLabel.text?.append(Constants.DATE_TODAY_HINT)
        }

        if Calendar.current.isDateInToday(endDatePicker.date) {
            endDateLabel.text?.append(Constants.DATE_TODAY_HINT)
        }
    }

    private func getTotalAgenciesCount() -> Int? {
        return filterOptions?.agencies?.count
    }

    // Count number of agencies that are enabled
    private func getSelectedAgenciesCount() -> Int {
        var count: Int = 0
        self.filterOptions?.agencies?.forEach({ (agency) in
            if agency.enabled {
                count += 1
            }
        })
        return count
    }

    private func updateSelectedAgenciesText() {
        let selectedAgenciesCount = getSelectedAgenciesCount()
        var selectedText: String

        if let totalAgenciesCount = getTotalAgenciesCount(), selectedAgenciesCount == totalAgenciesCount {
            // Display "All Selected" if all agencies are selected
            selectedText = String(Constants.ALL_SELECTED)
        } else {
            // Otherwise display number
            selectedText = String(selectedAgenciesCount)
        }

        selectedAgenciesLabel.text = selectedText + Constants.SELECTED_AGENCIES_HINT
    }

    private func updateMinMaxDates() {
        startDatePicker.maximumDate = endDatePicker.date
        endDatePicker.minimumDate = startDatePicker.date
    }

    private func updateFilterOptionsDates() {
        self.filterOptions?.startDate = startDatePicker.date
        self.filterOptions?.endDate = endDatePicker.date
    }
}

// UITableViewController functions
extension FilterOptionsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Toggle corresponding date picker
        if indexPath.row == 1 {
            // Only one date picker should be visible at any time
            // Collapse other cell if visible
            if isEndDatePickerVisible {
                toggleEndDatePicker()
            }
            toggleStartDatePicker()
        } else if indexPath.row == 3 {
            // Only one date picker should be visible at any time
            // Collapse other cell if visible
            if isStartDatePickerVisible {
                toggleStartDatePicker()
            }
            toggleEndDatePicker()
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !isStartDatePickerVisible && indexPath.row == Constants.START_DATE_PICKER_ROW {
            return 0
        } else if !isEndDatePickerVisible && indexPath.row == Constants.END_DATE_PICKER_ROW {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
}

extension FilterOptionsTableViewController: SelectTransitAgencyDelegate {
    func updateSelectedTransitAgencies(agencies: [FilterTransitAgency]?) {
        print("Update")
        self.filterOptions?.agencies = agencies
        updateSelectedAgenciesText()
    }
}

// Workaround for correct dialog size after rotating device
extension FilterOptionsTableViewController: MZFormSheetPresentationContentSizing {
    private enum FrameConstants {
        static let FILTER_DIALOG_SCALE_X: CGFloat = 0.9
        static let FILTER_DIALOG_SCALE_Y: CGFloat = 0.8
    }

    func shouldUseContentViewFrame(for presentationController: MZFormSheetPresentationController!) -> Bool {
        return true
    }

    func contentViewFrame(for presentationController: MZFormSheetPresentationController!, currentFrame: CGRect) -> CGRect {
        var frame = currentFrame
        frame.size.width = UIScreen.main.bounds.size.width * FrameConstants.FILTER_DIALOG_SCALE_X
        frame.size.height = UIScreen.main.bounds.size.height * FrameConstants.FILTER_DIALOG_SCALE_Y
        return frame
    }
}
