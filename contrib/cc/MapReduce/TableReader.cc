#include "TableReader.h"

namespace Mapreduce {
TableReader::TableReader(HadoopPipes::MapContext& context)
{    
  const HadoopPipes::JobConf *job = context.getJobConf();
  std::string tableName = job->get("hypertable.table.name");
  bool allColumns = job->getBoolean("hypertable.table.columns.all");

  m_client = new Client("MR", "conf/hypertable.cfg");

  m_table = m_client->open_table(tableName);

  ScanSpec scan_spec;

  std::string start_row;
  std::string end_row;
  std::string tablename;

  HadoopUtils::StringInStream stream(context.getInputSplit());
  HadoopUtils::deserializeString(tablename, stream);
  HadoopUtils::deserializeString(start_row, stream);
  HadoopUtils::deserializeString(end_row, stream);

  scan_spec.start_row = start_row.c_str();
  scan_spec.start_row_inclusive = true;

  scan_spec.end_row = end_row.c_str();
  scan_spec.end_row_inclusive = true;

  scan_spec.return_deletes = false;

  if (allColumns == false) {
    std::vector<std::string> columns;
    using namespace boost::algorithm;
    
    split(columns, job->get("hypertable.table.columns"), is_any_of(", "));
      BOOST_FOREACH(const std::string &c, columns) {
        scan_spec.columns.push_back(c.c_str());
      }
      m_scanner = m_table->create_scanner(scan_spec);
  } else {
    m_scanner = m_table->create_scanner(scan_spec);
  }
}

TableReader::~TableReader()
{
}

bool TableReader::next(std::string& key, std::string& value) {
  Cell cell;

  if (m_scanner->next(cell)) {
    key = cell.row_key;
    char *s = new char[cell.value_len+1];
    memcpy(s, cell.value, cell.value_len);
    s[cell.value_len] = 0;
    value = s;
    delete s;
    return true;
  } else {
    return false;
  }
}

}

