//
//  SelectTransitAgencyTableViewController.swift
//  PRESTO-Wallet
//
//  Created by Jeffrey on 2018-01-08.
//  Copyright © 2018 JeffreyCA. All rights reserved.
//

import MZFormSheetPresentationController
import UIKit

protocol SelectTransitAgencyDelegate: class {
    func updateSelectedTransitAgencies(agencies: [FilterTransitAgency]?)
}

class SelectTransitAgencyTableViewController: UITableViewController {
    weak var delegate: SelectTransitAgencyDelegate?
    var filterOptions: FilterOptions?
    var selectedRows: Int = 0

    @IBAction func resetSelection() {
        let shouldCheck: Bool

        if self.selectedRows == filterOptions?.agencies?.count {
            self.navigationItem.rightBarButtonItem?.title = "Select All"
            self.selectedRows = 0
            shouldCheck = false
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Deselect All"
            self.selectedRows = (filterOptions?.agencies?.count)!
            shouldCheck = true
        }

        // Deselect/select all agencies
        for row in 0 ..< tableView.numberOfRows(inSection: 0) {
            filterOptions?.agencies?[row].enabled = shouldCheck
            if shouldCheck {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: false)
            }
        }
    }

    private enum ImageConstants {
        static let DEFAULT_IMAGE: String = "icon_presto_green"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.clearsSelectionOnViewWillAppear = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.isEditing = true

        var index: Int = 0

        if let agencies = filterOptions?.agencies {
            for agency in agencies {
                if agency.enabled {
                    let indexPath = IndexPath(row: index, section: 0)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
                index += 1
            }
        }

        self.selectedRows = (filterOptions?.agencies?.count)!
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Update delegate class
        if isMovingFromParentViewController {
            delegate?.updateSelectedTransitAgencies(agencies: filterOptions?.agencies)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Table view functions
extension SelectTransitAgencyTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterOptions?.agencies?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let selectCell = cell as? SelectTransitAgencyTableViewCell {
            selectCell.name.text = filterOptions?.agencies?[indexPath.row].agency.rawValue ?? ""
            selectCell.icon.image = UIImage(named: filterOptions?.agencies?[indexPath.row].agency.getImage() ?? ImageConstants.DEFAULT_IMAGE)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        filterOptions?.agencies?[indexPath.row].enabled = true
        selectedRows += 1

        if selectedRows == filterOptions?.agencies?.count {
            self.navigationItem.rightBarButtonItem?.title = "Deselect All"
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        filterOptions?.agencies?[indexPath.row].enabled = false
        selectedRows -= 1

        self.navigationItem.rightBarButtonItem?.title = "Select All"
    }
}

// Workaround for correct dialog size after rotating device
extension SelectTransitAgencyTableViewController: MZFormSheetPresentationContentSizing {
    private enum Constants {
        static let FILTER_DIALOG_SCALE_X: CGFloat = 0.9
        static let FILTER_DIALOG_SCALE_Y: CGFloat = 0.8
    }

    func shouldUseContentViewFrame(for presentationController: MZFormSheetPresentationController!) -> Bool {
        return true
    }

    func contentViewFrame(for presentationController: MZFormSheetPresentationController!, currentFrame: CGRect) -> CGRect {
        var frame = currentFrame
        frame.size.width = UIScreen.main.bounds.size.width * Constants.FILTER_DIALOG_SCALE_X
        frame.size.height = UIScreen.main.bounds.size.height * Constants.FILTER_DIALOG_SCALE_Y
        return frame
    }
}
