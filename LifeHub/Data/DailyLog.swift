import Foundation
import SwiftData

@Model
class DailyLog {
    var date: Date
    var moodTags: [String]
    var didMeditate: Bool
    var didVisitGym: Bool
    var hadUnhealthyMeal: Bool

    init(date: Date, moodTags: [String], didMeditate: Bool, didVisitGym: Bool, hadUnhealthyMeal: Bool) {
        self.date = date
        self.moodTags = moodTags
        self.didMeditate = didMeditate
        self.didVisitGym = didVisitGym
        self.hadUnhealthyMeal = hadUnhealthyMeal
    }
}
