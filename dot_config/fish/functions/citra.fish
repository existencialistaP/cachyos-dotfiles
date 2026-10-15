function citra --wraps='QT_QPA_PLATFORM=xcb citra-qt' --description 'alias citra=QT_QPA_PLATFORM=xcb citra-qt'
    QT_QPA_PLATFORM=xcb citra-qt $argv
end
