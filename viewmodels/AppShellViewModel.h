#pragma once

#include <QObject>
#include <QVariantList>

class AppShellViewModel final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList modules READ modules CONSTANT)
    Q_PROPERTY(int selectedModuleIndex READ selectedModuleIndex NOTIFY selectedModuleIndexChanged)

public:
    explicit AppShellViewModel(QObject *parent = nullptr);

    QVariantList modules() const;
    int selectedModuleIndex() const;

    Q_INVOKABLE void selectModule(int index);

signals:
    void selectedModuleIndexChanged();

private:
    QVariantList m_modules;
    int m_selectedModuleIndex = 0;
};