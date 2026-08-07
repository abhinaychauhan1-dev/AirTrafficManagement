#include "viewmodels/AirTrafficViewModel.h"

#include <QtTest>

class SurveillanceViewModelTest final : public QObject
{
    Q_OBJECT

private slots:
    void filterClearAndSelectionStaySynchronized();
    void rangeFocusAndResetAreBounded();
    void surveillanceFeedMovesTracksAndUpdatesSectors();
    void alertAcknowledgementRearmsAfterConflictReturns();
};

void SurveillanceViewModelTest::filterClearAndSelectionStaySynchronized()
{
    AirTrafficViewModel viewModel;

    viewModel.setFlightFilter(QStringLiteral("IGO"));
    QCOMPARE(viewModel.filteredFlightCount(), 1);
    QCOMPARE(viewModel.selectedFilteredTrack(), 0);
    QCOMPARE(viewModel.selectedFlight().value("callSign").toString(), QStringLiteral("IGO613"));

    viewModel.setFlightFilter(QStringLiteral("NO MATCH"));
    QCOMPARE(viewModel.filteredFlightCount(), 0);
    QCOMPARE(viewModel.selectedFilteredTrack(), -1);

    viewModel.setFlightFilter(QString());
    QCOMPARE(viewModel.filteredFlightCount(), viewModel.flightCount());
    QCOMPARE(viewModel.selectedFlight().value("callSign").toString(), QStringLiteral("IGO613"));
}

void SurveillanceViewModelTest::rangeFocusAndResetAreBounded()
{
    AirTrafficViewModel viewModel;

    viewModel.changeRangeBySteps(-20);
    QCOMPARE(viewModel.rangeNm(), viewModel.minimumRangeNm());
    QVERIFY(viewModel.atMinimumRange());

    viewModel.resetRadarView();
    QCOMPARE(viewModel.rangeNm(), 80);
    QCOMPARE(viewModel.viewCenterX(), .5);
    QCOMPARE(viewModel.viewCenterY(), .51);

    viewModel.focusTrack(4);
    QCOMPARE(viewModel.selectedTrack(), 4);
    QCOMPARE(viewModel.rangeNm(), 40);
    QCOMPARE(viewModel.viewCenterX(), viewModel.selectedFlight().value("positionX").toReal());
    QCOMPARE(viewModel.viewCenterY(), viewModel.selectedFlight().value("positionY").toReal());

    viewModel.changeRangeBySteps(20);
    QCOMPARE(viewModel.rangeNm(), viewModel.maximumRangeNm());
    QVERIFY(viewModel.atMaximumRange());
}

void SurveillanceViewModelTest::surveillanceFeedMovesTracksAndUpdatesSectors()
{
    AirTrafficViewModel viewModel;
    const QVariantMap before = viewModel.selectedFlight();

    viewModel.advanceSurveillance();

    const QVariantMap after = viewModel.selectedFlight();
    QVERIFY(before.value("positionX").toReal() != after.value("positionX").toReal()
            || before.value("positionY").toReal() != after.value("positionY").toReal());

    int sectorTrackTotal = 0;
    const QVariantList sectors = viewModel.sectorLoads();
    sectorTrackTotal += sectors.at(0).toMap().value("trackCount").toInt();
    sectorTrackTotal += sectors.at(1).toMap().value("trackCount").toInt();
    QCOMPARE(sectorTrackTotal, viewModel.flightCount());
}

void SurveillanceViewModelTest::alertAcknowledgementRearmsAfterConflictReturns()
{
    AirTrafficViewModel viewModel;
    QVERIFY(viewModel.separationAlertActive());

    viewModel.acknowledgeSeparationAlert();
    QVERIFY(!viewModel.separationAlertActive());
    QCOMPARE(viewModel.alertCount(), 1);

    for (int tick = 0; tick < 15; ++tick)
        viewModel.advanceSurveillance();
    QCOMPARE(viewModel.alertCount(), 0);
    QVERIFY(!viewModel.separationAlertActive());

    for (int tick = 0; tick < 15; ++tick)
        viewModel.advanceSurveillance();
    QCOMPARE(viewModel.alertCount(), 1);
    QVERIFY(viewModel.separationAlertActive());
}

QTEST_GUILESS_MAIN(SurveillanceViewModelTest)

#include "SurveillanceViewModelTest.moc"