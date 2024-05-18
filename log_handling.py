from datetime import datetime
import logging
from logging import handlers as log_handlers
import os


def setup_logger(filename, logging_filter_time=1, str_handler=None, when='D', backup_count=60, log_level="info"):  # pragma: no cover
    datetime_format = "%d.%m.%Y %H:%M:%S"
    log_level_mapping = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warning": logging.WARNING,
        "error": logging.ERROR,
    }

    class DuplicateFilter(object):
        def __init__(self, formatter):
            self.msgs = {}
            self.formatter = formatter

        def filter(self, record):
            self.formatter.format(record)
            if logger.level == 10:
                return True
            msg = record.threadName + " " + str(record.msg)
            if msg in self.msgs.keys():
                if (datetime.strptime(record.asctime, datetime_format) - (datetime.strptime(self.msgs[msg], datetime_format))).total_seconds() < logging_filter_time:
                    return False
            self.msgs[msg] = record.asctime
            return True

    log_formatter = logging.Formatter("%(asctime)s [%(levelname)-7.7s] [%(threadName)-25.25s]   %(message)s", datetime_format)

    log_folder = "logs"
    os.makedirs(log_folder, exist_ok=True)
    filepath = os.path.join(log_folder, filename)
    file_handler = log_handlers.TimedRotatingFileHandler(filepath, encoding="UTF-8", when=when, backupCount=backup_count)
    file_handler.setFormatter(log_formatter)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(log_formatter)

    logger = logging.getLogger(filepath)
    logger.propagate = False

    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    # This is for testing, to be able to retrieve the logged messages, without having to read the actual file the message were written to
    if str_handler:
        str_handler = logging.StreamHandler(str_handler)
        str_handler.setFormatter(log_formatter)
        logger.addHandler(str_handler)

    logger.setLevel(log_level_mapping[log_level.lower()])

    dup_filter = DuplicateFilter(log_formatter)
    logger.addFilter(dup_filter)
    return logger


def close_log_handlers(log):
    handlers = log.handlers[:]
    for handler in handlers:
        handler.close()
        log.removeHandler(handler)


def main():
    log = setup_logger("example.log")
    log.debug('This message should go to the log file')
    log.info('So should this')
    log.warning('And this, too')
    log.error('And non-ASCII stuff, too, like Øresund and Malmö')
    close_log_handlers(log)


if __name__ == '__main__':
    main()
