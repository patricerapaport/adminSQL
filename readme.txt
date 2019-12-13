I think I made it

I’ve build a class which will be the Datasource of my tableView and I subclassed NSTableView as CTableView

class CTableView: NSTableView {
    func nbVisibleRows() -> Int {
    }
}

In CTableView, I have the function nbVisibleRows which return the number of visible rows. It(s implementation is:
 func nbVisibleRows() -> Int {
	return Int(superview!.frame.size.height / rowHeight)-1
 }

I subtract 1 from the number of visible rows because of the header of the tableView

for the Datasource:

Class CDatasource {
    var data : [NSDictionary]!
    var totalRows: Int!
    var limit: Int!
    var nbPagesInMemory: Int!
    var firstVisibleIndex: Int!
    var isFetchingData: Bool = false

    func destroyPageData (_ index: Int) {
	data.removeSubrange(index..<index+min(limit, data.count))
    }

    func isRowInMemory (_ row: Int) -> Bool {
  	return row >= firstVisibleIndex && row < firstVisibleIndex + data.count
    }

    func fetch (_ tableView: NSTableView, _ row: Int, completion: @escaping(Bool) -> Void) {
    }
}

extension CDatasource: NSTableviewDatasource {
    func  numberOfRows (in tableView: NSTableView) -> Int {
    	return totalRows == nil ? 0 : totalRows
    }
}

the variable totalRows is the total amount of rows my table has to display. this number is given by the function fetch of Datasource.

in Datasource, the variable data contains some rows to be shown in the NSTableView. Howmuch Data? it depends on the variables limit and nbPagesInMemory. Limit is the amount of visibleRows in NSTableView, and nbPagesInMemory is the amount of pages I want to be stocked in memory.

the variable firstVisibleIndex corresponds to the first  element of data. For instance, at the beginning, firstVisibleIndex has the value 0, and data contains the elements corresponding to row 0 to limit*nbPagesinMemory-1.

In the fetch function, I first destroy the some data, to be sure I don't have more than limit*nbPagesInMemory in the array of data: 

    func fetch (_ tableView: NSTableView, _ row: Int, completion: @escaping(Bool) -> Void) {
	isFetchingData = true
	
	//1/ Destroy some data
	if row < firstVisibleIndex {
       	    destroyPageData((nbPagesInMemory-1)*limit)
	    firstVisibleIndex -= limit
        } else {
            destroyPageData(0)
            firstVisibleIndex += limit
        }

	// 2 fetch the Data
	fetchData( {
            res, dict in
                if row < self.firstVisibleIndex {
                    self.data.insert(contentsOf: dict!["items"] as! [NSDictionary], at: 0)
                } else {
                    self.data.insert(contentsOf:dict!["items"] as! [NSDictionary], at: self.data.count)
                }

                // 3 reload rows
                let rows = NSIndexSet(indexesIn: NSMakeRange(row, self.firstVisibleRow+self.data.count-1)) as IndexSet
                let cols = NSIndexSet( indexesIn: NSMakeRange(0, tableview.numberOfColumns)) as IndexSet
                DispatchQueue.main.async {
                    self.isFetchingData = false
                    tableview.reloadData(forRowIndexes: rows, columnIndexes: cols)
                }
                completion(res)
            })
    }

In the NSViewController I have a variable queue which is a DispatchQueue
In the NSTableViewDelegate of the NSViewController, I have
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
	if dataSource.isFetchingDta {
	    return nii
	}
	if !dataSource.isRowInMemory (row) {
	    if tableColumn == tableView.tableColumns[0] {
		queue = DispatchQueue(label: "label for the queue", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
		queue.async {
                    self.Datasource.fetch(tableView, row, completion: {
                         res in
                         DispatchQueue.main.async {
                             self.queue = nil
                         }
             	    })
                }
	    }
	    return nil
	}
	
	... return the value of cells
    }

 

